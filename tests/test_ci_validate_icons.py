"""Regression checks for icons that exist on disk but are absent in the palette."""
from pathlib import Path
import runpy
import tempfile
import unittest
import contextlib
import io

from ci_validate_icons import extract_registered_components, validate_package_icon_loading, validate_bitmap_payloads


class PackageIconTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'pacote/packages').mkdir(parents=True)

    def put(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')

    def package(self, name, sources, dependencies=()):
        files = ''.join(f'<Item><Filename Value="{source}"/></Item>' for source in sources)
        requires = ''.join(f'<Item><PackageName Value="{dep}"/></Item>' for dep in dependencies)
        self.put(f'pacote/packages/{name}.lpk',
                 f'<CONFIG><Package><Files>{files}</Files><RequiredPkgs>{requires}</RequiredPkgs></Package></CONFIG>')

    def source(self):
        self.put('pacote/demo.pas', "unit demo; interface implementation procedure Register; begin RegisterComponents('Demo',[TDemo]); end; end.")
        self.put('pacote/demo.lrs', "LazarusResources.Add('tdemo','BMP',[#0]);")

    def check_loading(self):
        return validate_package_icon_loading(self.root, extract_registered_components(self.root))[0]

    def test_resource_on_disk_is_not_enough(self):
        self.source()
        self.package('sample', ['../demo.pas'])
        self.assertTrue(any("does not load the icon" in error for error in self.check_loading()))

    def test_palette_helper_loads_resource(self):
        self.source()
        self.put('pacote/packages/palette.pas', 'unit palette; interface implementation initialization {$I ../demo.lrs} end.')
        self.package('sample', ['../demo.pas', 'palette.pas'])
        self.assertEqual([], self.check_loading())

    def test_dependency_resource_is_available(self):
        self.source()
        self.put('pacote/packages/palette.pas', 'unit palette; interface implementation initialization {$I ../demo.lrs} end.')
        self.package('assets', ['palette.pas'])
        self.package('sample', ['../demo.pas'], ['assets'])
        self.assertEqual([], self.check_loading())

    def test_quoted_resource_path_with_spaces(self):
        self.source()
        self.put('pacote/with space/demo.lrs', "LazarusResources.Add('tdemo','BMP',[#0]);")
        self.put('pacote/packages/palette.pas', "unit palette; interface implementation initialization {$I '../with space/demo.lrs'} end.")
        self.package('sample', ['../demo.pas', 'palette.pas'])
        self.assertEqual([], self.check_loading())

    def test_unrelated_package_does_not_supply_icon(self):
        self.source()
        self.put('pacote/packages/palette.pas', 'unit palette; interface implementation initialization {$I ../demo.lrs} end.')
        self.package('assets', ['palette.pas'])
        self.package('sample', ['../demo.pas'])
        self.assertTrue(self.check_loading())

    def test_corrupted_bitmap_is_rejected(self):
        self.source()
        self.assertTrue(validate_bitmap_payloads(self.root))

    def test_generated_pictogram_decodes_as_bitmap(self):
        generator = runpy.run_path(str(Path(__file__).resolve().parents[1] / 'pacote/generate_all_icons.py'))
        pixels = generator['draw_icon']([240, 80, 80], 'IGNORED', 'TAIWifi')
        bitmap = generator['make_bmp'](pixels)
        self.put('pacote/wifi.lrs', generator['format_lrs_resource']('taiwifi', bitmap))
        self.assertEqual([], validate_bitmap_payloads(self.root))

    def test_unconfigured_component_fails_generation_check(self):
        self.source()
        generator = runpy.run_path(str(Path(__file__).resolve().parents[1] / 'pacote/generate_all_icons.py'))
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(generator['check_component_coverage'](self.root / 'pacote'))

    def test_generator_covers_all_registered_components(self):
        root = Path(__file__).resolve().parents[1]
        generator = runpy.run_path(str(root / 'pacote/generate_all_icons.py'))
        names = {name.lower() for entries in generator['icons_config'].values() for name, _, _ in entries}
        self.assertFalse(set(extract_registered_components(root)) - names)


if __name__ == '__main__':
    unittest.main()

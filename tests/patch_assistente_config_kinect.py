#!/usr/bin/env python3
"""
Adds Kinect controls to tsVisao in frmconfig.pas, frmconfig.lfm, and wires in main.pas.
"""

from pathlib import Path

SRC_DIR = Path(r"P:\maurinsoft\Assistente\src")
FRMCONFIG_PAS = SRC_DIR / "frmconfig.pas"
FRMCONFIG_LFM = SRC_DIR / "frmconfig.lfm"
MAIN_PAS = SRC_DIR / "main.pas"

def patch_frmconfig_pas():
    print("[1] Atualizando frmconfig.pas com controles do Kinect...")
    txt = FRMCONFIG_PAS.read_text(encoding="utf-8")

    if "chkKinectEnabled" not in txt:
        old_decl = "tsVisao: TTabSheet;"
        new_decl = """tsVisao: TTabSheet;
    chkKinectEnabled: TCheckBox;
    chkKinectSeated: TCheckBox;
    lblKinectDist: TLabel;
    edKinectMinDist: TEdit;
    edKinectMaxDist: TEdit;
    lblKinectTargets: TLabel;
    edKinectTargetLeft: TEdit;
    edKinectTargetRight: TEdit;
    edKinectTargetCenter: TEdit;"""
        txt = txt.replace(old_decl, new_decl, 1)
        FRMCONFIG_PAS.write_text(txt, encoding="utf-8")
        print("  OK: frmconfig.pas atualizado.")
    else:
        print("  OK: frmconfig.pas ja possui controles do Kinect.")

def patch_frmconfig_lfm():
    print("[2] Atualizando frmconfig.lfm com interface do Kinect na aba Visao...")
    txt = FRMCONFIG_LFM.read_text(encoding="cp1252", errors="ignore")

    if "chkKinectEnabled" not in txt:
        old_block = """      object edVerPort: TEdit
        Left = 180
        Height = 23
        Top = 35
        Width = 80
        TabOrder = 1
        Text = '5003'
      end
    end"""

        new_block = """      object edVerPort: TEdit
        Left = 180
        Height = 23
        Top = 35
        Width = 80
        TabOrder = 1
        Text = '5003'
      end
      object chkKinectEnabled: TCheckBox
        Left = 10
        Height = 19
        Top = 75
        Width = 260
        Caption = 'Ativar Kinect v1 como sensor principal'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object chkKinectSeated: TCheckBox
        Left = 10
        Height = 19
        Top = 100
        Width = 200
        Caption = 'Modo sentado (Seated Tracking)'
        Checked = True
        State = cbChecked
        TabOrder = 3
      end
      object lblKinectDist: TLabel
        Left = 10
        Height = 15
        Top = 130
        Width = 230
        Caption = 'Zona de Distancia (Min / Max metros):'
        ParentColor = False
      end
      object edKinectMinDist: TEdit
        Left = 10
        Height = 23
        Top = 150
        Width = 100
        TabOrder = 4
        Text = '0.8'
      end
      object edKinectMaxDist: TEdit
        Left = 120
        Height = 23
        Top = 150
        Width = 100
        TabOrder = 5
        Text = '2.5'
      end
      object lblKinectTargets: TLabel
        Left = 10
        Height = 15
        Top = 185
        Width = 260
        Caption = 'Alvos Deiticos (Esq / Centro / Dir):'
        ParentColor = False
      end
      object edKinectTargetLeft: TEdit
        Left = 10
        Height = 23
        Top = 205
        Width = 80
        TabOrder = 6
        Text = 'ECG'
      end
      object edKinectTargetCenter: TEdit
        Left = 95
        Height = 23
        Top = 205
        Width = 80
        TabOrder = 7
        Text = 'Robotinics'
      end
      object edKinectTargetRight: TEdit
        Left = 180
        Height = 23
        Top = 205
        Width = 80
        TabOrder = 8
        Text = 'Hemacias'
      end
    end"""

        txt = txt.replace(old_block, new_block, 1)
        FRMCONFIG_LFM.write_text(txt, encoding="cp1252")
        print("  OK: frmconfig.lfm atualizado com controles visuais.")
    else:
        print("  OK: frmconfig.lfm ja possui controles do Kinect.")

def patch_main_pas():
    print("[3] Atualizando leitura e gravacao do Kinect no btAbrirConfigClick...")
    txt = MAIN_PAS.read_text(encoding="utf-8")

    if "FormCfg.chkKinectEnabled.Checked :=" not in txt:
        # Load in FormCfg
        old_load = "FormCfg.edPostSchema.Text := FSetMain.SchemaPost;"
        new_load = """FormCfg.edPostSchema.Text := FSetMain.SchemaPost;

      // Aba Visao / Kinect
      FormCfg.chkKinectEnabled.Checked := FSetMain.KinectEnabled;
      FormCfg.chkKinectSeated.Checked := FSetMain.KinectSeatedMode;
      FormCfg.edKinectMinDist.Text := FloatToStr(FSetMain.KinectMinDistance);
      FormCfg.edKinectMaxDist.Text := FloatToStr(FSetMain.KinectMaxDistance);
      FormCfg.edKinectTargetLeft.Text := FSetMain.KinectTargetLeft;
      FormCfg.edKinectTargetRight.Text := FSetMain.KinectTargetRight;
      FormCfg.edKinectTargetCenter.Text := FSetMain.KinectTargetCenter;"""
        txt = txt.replace(old_load, new_load, 1)

        # Save from FormCfg
        old_save = "FSetMain.PasswordPost := Trim(FormCfg.edPostPass.Text);"
        new_save = """FSetMain.PasswordPost := Trim(FormCfg.edPostPass.Text);

      // Salva Visao / Kinect
      FSetMain.KinectEnabled := FormCfg.chkKinectEnabled.Checked;
      FSetMain.KinectSeatedMode := FormCfg.chkKinectSeated.Checked;
      FSetMain.KinectMinDistance := StrToFloatDef(Trim(FormCfg.edKinectMinDist.Text), 0.8);
      FSetMain.KinectMaxDistance := StrToFloatDef(Trim(FormCfg.edKinectMaxDist.Text), 2.5);
      FSetMain.KinectTargetLeft := Trim(FormCfg.edKinectTargetLeft.Text);
      FSetMain.KinectTargetRight := Trim(FormCfg.edKinectTargetRight.Text);
      FSetMain.KinectTargetCenter := Trim(FormCfg.edKinectTargetCenter.Text);"""
        txt = txt.replace(old_save, new_save, 1)

        MAIN_PAS.write_text(txt, encoding="utf-8")
        print("  OK: main.pas atualizado com transferencia de dados de configuracao.")
    else:
        print("  OK: main.pas ja possui transferencia de configuracao do Kinect.")

def main():
    patch_frmconfig_pas()
    patch_frmconfig_lfm()
    patch_main_pas()
    print("Atualizacao das configuracoes do Kinect concluida!")

if __name__ == "__main__":
    main()

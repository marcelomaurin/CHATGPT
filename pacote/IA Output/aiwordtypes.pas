unit aiwordtypes;

{$mode objfpc}{$H+}

interface

type
  TAIWordAlignment = (
    waLeft,
    waCenter,
    waRight,
    waJustify
  );

  TAIWordImagePosition = (
    wipInline,
    wipFloating,
    wipBehindText,
    wipInFrontOfText,
    wipSquareWrap
  );

  TAIWordPaperSize = (
    wpsA4,
    wpsLetter,
    wpsLegal
  );

  TAIWordOrientation = (
    woPortrait,
    woLandscape
  );

  TAIWordVerticalAlignment = (
    wvaTop,
    wvaCenter,
    wvaBottom
  );

implementation

end.

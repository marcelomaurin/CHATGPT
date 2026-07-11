# POS Printer Protocol Review Notes

During diagnostic analysis of the old printing implementation, the following architectural design issues were identified and addressed:

1. **"Native OS" Protocol Misplacement:**
   - *Issue:* Native OS printing was defined as a printer language protocol (`ppNative`), which is conceptually incorrect. Native printing is a rendering mode using GDI/spooler APIs, not a markup/protocol.
   - *Fix:* Extracted `rmNativeCanvas` to `TPrinterRenderMode` and separated it from the low-level languages (`plEscPos`, `plZpl`, `plTspl`, `plEpl`).

2. **Connection State Side Effects:**
   - *Issue:* Opening a connection immediately transmitted printer reset/initialize sequences, which breaks label alignment and wastes stock on barcode printers.
   - *Fix:* Separated `OpenConnection` (network/socket creation only) from `BeginJob` (initiating document/markup generation).

3. **Cutter (`CutPaper`) Misuse:**
   - *Issue:* Comand for ending labels (`^XZ`, `PRINT 1,1`, `P1`) was bound directly to the paper cutting function (`CutPaper`).
   - *Fix:* Explicitly separated `EndLabel`/`PrintLabel` (printing markup) from `CutPaper` (physical cutting, if supported by the model profile).

4. **Weak Simulation vs. Real Output:**
   - *Issue:* The demo had a completely separate mock execution tree that did not execute the actual driver logic.
   - *Fix:* Replaced simulation checkboxes with a unified `PreviewOnly` mode that generates real raw commands to either display (Preview) or transmit (Spool).

5. **String Encoding Fragility:**
   - *Issue:* High-level commands used string concatenation and character byte casting, causing encoding issues for accented chars (CP850/CP437/Win1252) and binary payloads.
   - *Fix:* Introduced `TAIByteBuilder` for precise byte array (`TBytes`) accumulation and encoding.

# TAIFrameBuffer Documentation

The `TAIFrameBuffer` component acts as a circular in-memory buffer for `TBitmap` frames, providing structural support for stream caching, temporal filter processing, and multi-frame processing pipelines.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIFrameBuffer`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `MaxFrames` | `Integer` | `2` | Capacity limit of the circular queue. Adding more frames will overwrite the oldest ones. |
| `Count` | `Integer` | `0` | (Read-only) Current number of valid frames stored in the buffer. |

## Key Methods

- **`function AddFrame(ABitmap: TBitmap): Boolean`**
  Copies the provided `TBitmap` into the circular buffer. Automatically deletes the oldest frame if capacity (`MaxFrames`) is exceeded. Returns `True` on success.

- **`function GetLastFrame: TBitmap`**
  Returns the most recently added frame in the buffer. Returns `nil` if the buffer is empty.

- **`function GetPreviousFrame: TBitmap`**
  Returns the second most recently added frame. Returns `nil` if the buffer has fewer than 2 frames.

- **`procedure Clear`**
  Cleans and frees all stored frames from memory, resetting `Count` to `0`.

## Memory Management
`TAIFrameBuffer` manages the lifecycle of stored `TBitmap` instances. Bitmaps passed via `AddFrame` are duplicated (using `Assign`), so caller-owned bitmaps can be modified or freed independently.

## Example Usage

```pascal
var
  Buffer: TAIFrameBuffer;
  Bmp: TBitmap;
begin
  Buffer := TAIFrameBuffer.Create(nil);
  Buffer.MaxFrames := 5; // Queue of up to 5 frames
  
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile('frame1.bmp');
    Buffer.AddFrame(Bmp);
    
    Bmp.LoadFromFile('frame2.bmp');
    Buffer.AddFrame(Bmp);
    
    WriteLn('Cached frames in buffer: ', Buffer.Count);
    WriteLn('Current Frame Width: ', Buffer.GetLastFrame.Width);
    WriteLn('Previous Frame Width: ', Buffer.GetPreviousFrame.Width);
  finally
    Bmp.Free;
    Buffer.Free; // Automatically frees all 5 buffered bitmaps
  end;
end;
```

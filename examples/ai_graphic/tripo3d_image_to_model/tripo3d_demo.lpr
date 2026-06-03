program tripo3d_demo;

{$mode objfpc}{$H+}

uses
  Interfaces, SysUtils, Classes, aitripo3dclient, ai3dmodelviewer, aimodel3d, aibase;

var
  Client: TAITripo3DClient;
  Viewer: TAI3DModelViewer;
  Model: TAIModel3D;
  ImagePath: string;
  OutputModelPath: string;
  Progress: Integer;
  DownloadURL: string;
  Status: string;
  APIKey: string;
begin
  Writeln('=== Tripo3D Image-to-3D Model Generator Demo ===');
  Writeln;

  ImagePath := 'test_object.png';
  OutputModelPath := 'generated_model.stl';

  // 1. Instantiating components
  Client := TAITripo3DClient.Create(nil);
  Viewer := TAI3DModelViewer.Create(nil);
  Model := TAIModel3D.Create(nil);
  try
    // Connect components
    Viewer.Model := Model;
    
    // Check if API key is set
    APIKey := Client.APIKey;
    if APIKey = '' then
    begin
      Writeln('WARNING: Tripo3D API Key is not set.');
      Writeln('Please set the TRIPO3D_API_KEY environment variable or assign Client.APIKey.');
      Writeln('Operating in Simulation / Demo mode...');
      Writeln;
      
      // Simulate task creation
      Writeln('Simulating task creation...');
      Client.LastTaskId := 'simulated_task_12345';
      Writeln('Task created successfully. Task ID: ', Client.LastTaskId);
      
      // Simulate status checking loop
      Writeln('Simulating task polling...');
      Progress := 0;
      while Progress < 100 do
      begin
        Sleep(500);
        Inc(Progress, 25);
        Writeln('Progress: ', Progress, '%');
      end;
      
      Writeln('Model generation succeeded.');
      Writeln('Simulating model download...');
      
      // Load a dummy file path to Model
      Model.LoadFromFile(OutputModelPath);
      Writeln('Visualizing model in viewer...');
      Viewer.Invalidate;
      
      Writeln('Demo finished successfully in Simulation mode.');
      Exit;
    end;

    // Actual execution flow (requires internet and valid API key)
    if not FileExists(ImagePath) then
    begin
      Writeln('Error: Local image "test_object.png" not found.');
      Writeln('Please place an image file named "test_object.png" in the execution directory.');
      Exit;
    end;

    Writeln('Sending image "test_object.png" to Tripo3D...');
    if Client.GenerateFromImage(ImagePath) then
    begin
      Writeln('Task Created. Task ID: ', Client.LastTaskId);
      Writeln('Polling task status...');
      
      repeat
        Sleep(Client.PollingInterval);
        Status := Client.CheckStatus(Client.LastTaskId, Progress, DownloadURL);
        Writeln('Status: ', Status, ' (', Progress, '%)');
      until (Status = 'success') or (Status = 'failed');

      if Status = 'success' then
      begin
        Writeln('Generation complete! Downloading model...');
        if Client.DownloadModel(DownloadURL, OutputModelPath) then
        begin
          Writeln('Model downloaded. Loading in Model3D...');
          Model.LoadFromFile(OutputModelPath);
          Writeln('Visualizing model in 3D Viewer...');
          Viewer.Invalidate;
          Writeln('Process completed successfully!');
        end
        else
          Writeln('Error: Failed to download the model from URL: ', DownloadURL);
      end
      else
        Writeln('Error: Generation failed on Tripo3D servers: ', Client.LastError);
    end
    else
      Writeln('Error generating model: ', Client.LastError);

  finally
    Model.Free;
    Viewer.Free;
    Client.Free;
  end;
  
  Writeln;
  Writeln('Press [Enter] to exit.');
  Readln;
end.

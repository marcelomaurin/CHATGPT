program ros_robotics_demo;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, airosagent;

var
  ROS: TAIROSAgent;
  Robot: TAIRobotAgent;
begin
  ROS := TAIROSAgent.Create(nil);
  Robot := TAIRobotAgent.Create(nil);
  try
    Robot.ROS := ROS;

    Writeln('ROS 2 robotics demo');
    Writeln('Control is blocked by default: AllowControl=False');

    if ROS.CheckROS then
    begin
      Writeln('ROS 2 CLI detected.');
      if ROS.ListNodes then
        Writeln('Nodes:' + LineEnding + ROS.StdOutText)
      else
        Writeln('Node list error: ' + ROS.LastError);

      if ROS.ListTopics(True) then
        Writeln('Topics:' + LineEnding + ROS.StdOutText)
      else
        Writeln('Topic list error: ' + ROS.LastError);
    end
    else
      Writeln('ROS 2 CLI not available: ' + ROS.LastError);

    { To control a configured robot explicitly enable:
        ROS.AllowControl := True;
        Robot.CmdVelTopic := '/cmd_vel';
        Robot.Forward(0.10);
        Robot.StopRobot;
      Keep disabled unless the robot/simulator and safety limits are configured. }
  finally
    Robot.Free;
    ROS.Free;
  end;
end.

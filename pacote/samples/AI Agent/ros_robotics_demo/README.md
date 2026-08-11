# ROS Robotics Agent Demo

Sample Lazarus/Free Pascal for `TAIROSAgent` and `TAIRobotAgent`.

## Requirements

- Lazarus / Free Pascal
- package `openai_agent`
- ROS 2 installed and the `ros2` CLI available in PATH
- for robot movement, a ROS 2 robot or simulator exposing a `geometry_msgs/msg/Twist` velocity topic (default `/cmd_vel`)

## Safety

`TAIROSAgent.AllowControl` defaults to `False`.

Read/introspection operations such as listing nodes, topics and services are allowed. Publishing topics, calling services and changing parameters are blocked until control is explicitly enabled.

```pascal
ROS.AllowControl := True;
Robot.CmdVelTopic := '/cmd_vel';
Robot.Forward(0.10);
Robot.StopRobot;
```

Configure speed limits and verify the robot/simulator before enabling control.

## Main API

`TAIROSAgent`:

- `CheckROS`
- `ListNodes`
- `ListTopics`
- `ListServices`
- `ListActions`
- `TopicInfo`
- `TopicEchoOnce`
- `PublishOnce`
- `CallService`
- `GetParam`
- `SetParam`

`TAIRobotAgent`:

- `Move`
- `StopRobot`
- `Forward`
- `Backward`
- `RotateLeft`
- `RotateRight`

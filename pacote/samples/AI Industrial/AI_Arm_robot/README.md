# AI_Arm_robot sample

This sample shows the `AI_Arm_robot` component in the `AI Industrial` tab.

## What it does
- Loads a 6-axis arm preset based on the SG90 arm you described.
- The joint controls are automatically generated and managed by the `TAI_ARM_RobotControl` component (simply set its `Arm` and `Container` properties). Loading or reloading a JSON model with a different number of axes automatically reconstructs the control rows and sliders.
- Solves inverse kinematics from a target `X, Y, Z` point.
- Renders the arm with the `TAI_Arm_robotViewer` component.

## How to use
1. Open the project in Lazarus.
2. Make sure the `openai_industrial` package is available.
3. Build and run the sample.
4. Adjust the joint angles or enter a target position and click `Resolver IK`.

## Notes
- Joint types and axes are defined in `AI_Arm_robot.model.json`.
- Joints `1`, `2`, and `3` are angular joints around the Y axis.
- The kinematics and printed SG90 model can be changed for your exact geometry.
- If you want, the next step can be a hardware output component for SG90 over Arduino/PCA9685.

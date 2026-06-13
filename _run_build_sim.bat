@echo off
cd /d D:\projetos\maurinsoft\CHATGPT
call tools\mediapipe_pose_build\build_pose_bridge_win64.bat SIM > build_sim_output.log 2>&1
echo Exit code: %ERRORLEVEL% >> build_sim_output.log

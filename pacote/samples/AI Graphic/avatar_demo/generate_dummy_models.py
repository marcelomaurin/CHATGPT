import os
import json
import subprocess

def main():
    # Target directory is the directory of this script
    target_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Target directory: {target_dir}")
    
    # 1. Write the .rig file
    rig_path = os.path.join(target_dir, "human_dummy.rig")
    rig_content = """# Name | ParentName | OffsetX | OffsetY | OffsetZ
pelvis | -1 | 0.0 | 0.2 | 0.0
spine | pelvis | 0.0 | 0.4 | 0.0
neck | spine | 0.0 | 0.1 | 0.0
head | neck | 0.0 | 0.2 | 0.0
left_shoulder | spine | -0.3 | 0.0 | 0.0
left_elbow | left_shoulder | -0.4 | 0.0 | 0.0
right_shoulder | spine | 0.3 | 0.0 | 0.0
right_elbow | right_shoulder | 0.4 | 0.0 | 0.0
left_hip | pelvis | -0.15 | -0.5 | 0.0
left_knee | left_hip | 0.0 | -0.5 | 0.0
right_hip | pelvis | 0.15 | -0.5 | 0.0
right_knee | right_hip | 0.0 | -0.5 | 0.0
"""
    with open(rig_path, "w", encoding="utf-8") as f:
        f.write(rig_content)
    print("Generated human_dummy.rig")

    # 2. Write the standalone .gltf file
    gltf_path = os.path.join(target_dir, "human_dummy.gltf")
    gltf_nodes = [
        {"name": "pelvis", "translation": [0.0, 0.2, 0.0], "children": [1, 8, 10]},
        {"name": "spine", "translation": [0.0, 0.4, 0.0], "children": [2, 4, 6]},
        {"name": "neck", "translation": [0.0, 0.1, 0.0], "children": [3]},
        {"name": "head", "translation": [0.0, 0.2, 0.0]},
        {"name": "left_shoulder", "translation": [-0.3, 0.0, 0.0], "children": [5]},
        {"name": "left_elbow", "translation": [-0.4, 0.0, 0.0]},
        {"name": "right_shoulder", "translation": [0.3, 0.0, 0.0], "children": [7]},
        {"name": "right_elbow", "translation": [0.4, 0.0, 0.0]},
        {"name": "left_hip", "translation": [-0.15, -0.5, 0.0], "children": [9]},
        {"name": "left_knee", "translation": [0.0, -0.5, 0.0]},
        {"name": "right_hip", "translation": [0.15, -0.5, 0.0], "children": [11]},
        {"name": "right_knee", "translation": [0.0, -0.5, 0.0]}
    ]
    gltf_data = {
        "asset": {
            "version": "2.0",
            "generator": "Handwritten"
        },
        "scenes": [
            {
                "nodes": [0]
            }
        ],
        "scene": 0,
        "nodes": gltf_nodes
    }
    with open(gltf_path, "w", encoding="utf-8") as f:
        json.dump(gltf_data, f, indent=2)
    print("Generated human_dummy.gltf")

    # 3. Write a Python script to execute inside Blender
    blender_script_path = os.path.join(target_dir, "temp_blender_gen.py")
    blender_script_content = f"""import bpy
import os

# Delete all objects in scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Create armature
bpy.ops.object.armature_add(enter_editmode=True, align='WORLD', location=(0, 0, 0))
arm_obj = bpy.context.active_object
arm_data = arm_obj.data
arm_data.name = 'HumanDummyArmature'
arm_obj.name = 'human_dummy'

eb = arm_data.edit_bones

# Pelvis: starts at (0, 0, 0), ends at (0, 0, 0.2)
pelvis = eb[0]
pelvis.name = 'pelvis'
pelvis.head = (0.0, 0.0, 0.0)
pelvis.tail = (0.0, 0.0, 0.2)

# Spine: starts at (0, 0, 0.2), ends at (0, 0, 0.6)
spine = eb.new('spine')
spine.parent = pelvis
spine.head = (0.0, 0.0, 0.2)
spine.tail = (0.0, 0.0, 0.6)

# Neck: starts at (0, 0, 0.6), ends at (0, 0, 0.7)
neck = eb.new('neck')
neck.parent = spine
neck.head = (0.0, 0.0, 0.6)
neck.tail = (0.0, 0.0, 0.7)

# Head: starts at (0, 0, 0.7), ends at (0, 0, 0.9)
head = eb.new('head')
head.parent = neck
head.head = (0.0, 0.0, 0.7)
head.tail = (0.0, 0.0, 0.9)

# Left Shoulder: starts at (0, 0, 0.6), ends at (-0.3, 0, 0.6)
l_shoulder = eb.new('left_shoulder')
l_shoulder.parent = spine
l_shoulder.head = (0.0, 0.0, 0.6)
l_shoulder.tail = (-0.3, 0.0, 0.6)

# Left Elbow: starts at (-0.3, 0, 0.6), ends at (-0.7, 0, 0.6)
l_elbow = eb.new('left_elbow')
l_elbow.parent = l_shoulder
l_elbow.head = (-0.3, 0.0, 0.6)
l_elbow.tail = (-0.7, 0.0, 0.6)

# Right Shoulder: starts at (0, 0, 0.6), ends at (0.3, 0, 0.6)
r_shoulder = eb.new('right_shoulder')
r_shoulder.parent = spine
r_shoulder.head = (0.0, 0.0, 0.6)
r_shoulder.tail = (0.3, 0.0, 0.6)

# Right Elbow: starts at (0.3, 0, 0.6), ends at (0.7, 0, 0.6)
r_elbow = eb.new('right_elbow')
r_elbow.parent = r_shoulder
r_elbow.head = (0.3, 0.0, 0.6)
r_elbow.tail = (0.7, 0.0, 0.6)

# Left Hip: starts at (0, 0, 0.2), ends at (-0.15, 0, -0.3)
l_hip = eb.new('left_hip')
l_hip.parent = pelvis
l_hip.head = (0.0, 0.0, 0.2)
l_hip.tail = (-0.15, 0.0, -0.3)

# Left Knee: starts at (-0.15, 0, -0.3), ends at (-0.15, 0, -0.8)
l_knee = eb.new('left_knee')
l_knee.parent = l_hip
l_knee.head = (-0.15, 0.0, -0.3)
l_knee.tail = (-0.15, 0.0, -0.8)

# Right Hip: starts at (0, 0, 0.2), ends at (0.15, 0, -0.3)
r_hip = eb.new('right_hip')
r_hip.parent = pelvis
r_hip.head = (0.0, 0.0, 0.2)
r_hip.tail = (0.15, 0.0, -0.3)

# Right Knee: starts at (0.15, 0, -0.3), ends at (0.15, 0, -0.8)
r_knee = eb.new('right_knee')
r_knee.parent = r_hip
r_knee.head = (0.15, 0.0, -0.3)
r_knee.tail = (0.15, 0.0, -0.8)

bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj

# Save .blend file
blend_file = os.path.join('{target_dir.replace("\\", "/")}', 'human_dummy.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("Blender saved human_dummy.blend successfully.")

# Export .glb
glb_file = os.path.join('{target_dir.replace("\\", "/")}', 'human_dummy.glb')
bpy.ops.export_scene.gltf(filepath=glb_file, export_format='GLB', use_selection=True)
print("Blender exported human_dummy.glb successfully.")

# Export .dae (Collada)
dae_file = os.path.join('{target_dir.replace("\\", "/")}', 'human_dummy.dae')
bpy.ops.wm.collada_export(filepath=dae_file, selected=True)
print("Blender exported human_dummy.dae successfully.")

# Export .bvh (Biovision Hierarchy)
bvh_file = os.path.join('{target_dir.replace("\\", "/")}', 'human_dummy.bvh')
bpy.ops.export_anim.bvh(filepath=bvh_file)
print("Blender exported human_dummy.bvh successfully.")
"""

    with open(blender_script_path, "w", encoding="utf-8") as f:
        f.write(blender_script_content)

    # 4. Invoke Blender in background to run the script
    blender_exe = "C:\\Program Files\\Blender Foundation\\Blender 4.3\\blender.exe"
    if os.path.exists(blender_exe):
        print("Blender 4.3 found. Generating .blend, .glb, .dae, and .bvh...")
        try:
            subprocess.run([blender_exe, "--background", "--python", blender_script_path], check=True)
            print("Successfully ran Blender generator script.")
        except Exception as e:
            print(f"Error executing Blender: {e}")
    else:
        print(f"Blender executable not found at: {blender_exe}")
        # If Blender is not available, we can write a basic BVH and DAE from Python.
        # But since we checked and it is available, it should succeed.
        
    # Clean up temporary script
    if os.path.exists(blender_script_path):
        os.remove(blender_script_path)
        
    print("Done!")

if __name__ == "__main__":
    main()

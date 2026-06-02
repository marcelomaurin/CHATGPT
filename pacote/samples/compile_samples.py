import os
import subprocess
import sys

def main():
    samples_dir = os.path.dirname(os.path.abspath(__file__))
    lazbuild_path = r"C:\lazarus\lazbuild.exe"
    
    if not os.path.exists(lazbuild_path):
        print(f"Error: lazbuild.exe not found at {lazbuild_path}")
        sys.exit(1)
        
    print(f"Scanning for Lazarus projects in {samples_dir}...")
    lpi_files = []
    for root, dirs, files in os.walk(samples_dir):
        if "backup" in root.lower() or "lib" in root.lower():
            continue
        for file in files:
            if file.endswith(".lpi"):
                lpi_files.append(os.path.join(root, file))
                
    print(f"Found {len(lpi_files)} project(s) to compile.")
    success_count = 0
    failed_projects = []
    
    for lpi in lpi_files:
        rel_path = os.path.relpath(lpi, samples_dir)
        print(f"\n==================================================")
        print(f"Compiling: {rel_path}")
        print(f"==================================================")
        
        # Run lazbuild
        res = subprocess.run([lazbuild_path, lpi], capture_output=True, text=True)
        if res.returncode == 0:
            print(f"SUCCESS: {rel_path}")
            success_count += 1
        else:
            print(f"FAILED: {rel_path}")
            print("STDOUT:")
            print(res.stdout)
            print("STDERR:")
            print(res.stderr)
            failed_projects.append(rel_path)
            
    print("\n==================================================")
    print("Compilation Summary:")
    print(f"Total: {len(lpi_files)}")
    print(f"Success: {success_count}")
    print(f"Failed: {len(failed_projects)}")
    if failed_projects:
        print("Failed projects:")
        for fp in failed_projects:
            print(f"  - {fp}")
        sys.exit(1)
    else:
        print("All projects compiled successfully!")
        sys.exit(0)

if __name__ == "__main__":
    main()

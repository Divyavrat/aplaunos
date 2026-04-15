import os
import subprocess

def run_builds(root_dir):
    # Ensure toolchain is in path so fasm/nasm are detected
    toolchain_dir = os.path.abspath('toolchain')
    os.environ['PATH'] = f"{toolchain_dir};{os.environ.get('PATH', '')}"

    for current_dir, dirs, files in os.walk(root_dir):
        if 'build.bat' in files:
            bat_path = os.path.join(current_dir, 'build.bat')
            print(f"-- Building in {current_dir} --")
            with open(bat_path, 'r') as f:
                lines = f.readlines()
            
            for line in lines:
                line = line.strip()
                if not line or line.lower().startswith('rem') or line.lower() in ('pause', 'exit'):
                    continue
                
                print(f"  > {line}")
                try:
                    subprocess.run(line, shell=True, cwd=current_dir, check=True)
                except Exception as e:
                    print(f"  [Error] {e}")

if __name__ == '__main__':
    run_builds('src')

import os
import subprocess
import shutil

def run_builds():
    src_dir = os.path.abspath('src')
    build_dir = os.path.abspath('build')
    sysroot_dir = os.path.abspath('sysroot')
    
    # Ensure toolchain is in path
    toolchain_dir = os.path.abspath('toolchain')
    os.environ['PATH'] = f"{toolchain_dir};{os.environ.get('PATH', '')}"

    exclude_dirs = ['boot', 'kernel', 'core']

    for root, dirs, files in os.walk(src_dir):
        # Skip excluded dirs if we are at the top level of src
        if os.path.abspath(root) == src_dir:
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
        for file in files:
            if file.lower().endswith('.asm'):
                asm_path = os.path.join(root, file)
                base_name = os.path.splitext(file)[0]
                out_name = f"{base_name}.com"
                
                # Calculate relative path to preserve directory structure
                rel_path = os.path.relpath(root, src_dir)
                if rel_path == '.':
                    rel_path = ''
                    
                target_build_dir = os.path.join(build_dir, rel_path)
                target_sysroot_dir = os.path.join(sysroot_dir, rel_path)
                
                os.makedirs(target_build_dir, exist_ok=True)
                os.makedirs(target_sysroot_dir, exist_ok=True)
                
                out_path = os.path.join(target_build_dir, out_name)
                
                print(f"Building {os.path.join(rel_path, file)}...")
                
                # Try FASM first
                cmd_fasm = f'fasm "{file}" "{out_path}"'
                cmd_nasm = f'nasm "{file}" -f bin -O1 -o "{out_path}"'
                
                success = False
                try:
                    result = subprocess.run(cmd_fasm, shell=True, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    if result.returncode == 0:
                        success = True
                except:
                    pass
                
                if not success:
                    # Try NASM
                    try:
                        result = subprocess.run(cmd_nasm, shell=True, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                        if result.returncode == 0:
                            success = True
                    except:
                        pass
                
                if success and os.path.exists(out_path):
                    sysroot_dest = os.path.join(target_sysroot_dir, out_name)
                    shutil.copy2(out_path, sysroot_dest)
                    print(f"  -> Built and copied to {os.path.join('sysroot', rel_path, out_name)}")
                else:
                    print(f"  [Error] Failed to compile {file}")

if __name__ == '__main__':
    run_builds()

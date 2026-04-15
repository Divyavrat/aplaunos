import os
from pyfatfs.PyFatFS import PyFatFS
import traceback

def create_directory_structure(fat_fs, path):
    parts = path.split('/')
    current = ""
    for part in parts:
        if not part: continue
        current = f"{current}/{part}" if current else part
        if not fat_fs.isdir(current):
            try:
                fat_fs.makedir(current)
            except Exception as e:
                print(f"Directory {current} exists or error: {e}")

def inject_files(img_path, src_dir):
    try:
        with PyFatFS(filename=img_path) as fat_fs:
            print("Successfully opened " + img_path)
            for root, dirs, files in os.walk(src_dir):
                rel_dir = os.path.relpath(root, src_dir).replace('\\', '/')
                if rel_dir == '.':
                    rel_dir = ''
                
                if rel_dir:
                    create_directory_structure(fat_fs, rel_dir)

                for fname in files:
                    src_file = os.path.join(root, fname)
                    dest_file = f"{rel_dir}/{fname}" if rel_dir else fname
                    if dest_file.startswith('/'):
                        dest_file = dest_file[1:]
                    
                    try:
                        with open(src_file, 'rb') as f_src:
                            with fat_fs.open(dest_file, 'wb') as f_dst:
                                f_dst.write(f_src.read())
                        print(f"Copied {fname} to {dest_file}")
                    except Exception as e:
                        print(f"Error copying {fname}: {e}")
                        
        print("Success! All OS files copied into " + img_path)
    except Exception as e:
        print("Failed to use PyFatFS:")
        traceback.print_exc()

if __name__ == '__main__':
    inject_files('fat16.img', 'sysroot')

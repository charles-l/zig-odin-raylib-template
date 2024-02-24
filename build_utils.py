import urllib.request
import platform
import zipfile
import os
import stat

def setup_odin(args):
    """Download/unpack odin"""
    ziptarget = ""
    if platform.system() == "Windows":
        ziptarget = "windows"
    elif platform.system() == "Linux":
        ziptarget = "ubuntu"
    elif platform.system() == "Darwin":
        ziptarget = "macos"

    zipfilename = f"odin-{ziptarget}-amd64-dev-2024-02.zip"
    url = f"https://github.com/odin-lang/Odin/releases/download/dev-2024-02/{zipfilename}"

    zippath = f"zig-cache/tmp/{zipfilename}"

    if not os.path.exists(zippath):
        print("Downloading odin binary:", url)
        urllib.request.urlretrieve(url, zippath)

    target_dir = os.path.dirname(args.odin_bin_path)
    print(f"Extracting {zippath} to {target_dir}/")
    with zipfile.ZipFile(zippath, 'r') as z:
        z.extractall(target_dir)

    st = os.stat(f'{target_dir}/odin')
    os.chmod(f'{target_dir}/odin', st.st_mode | stat.S_IEXEC)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(title='subcommands')
    setup_odin_parser = subparsers.add_parser('setup-odin')
    setup_odin_parser.add_argument('odin_bin_path')
    setup_odin_parser.set_defaults(func=setup_odin)
    args = parser.parse_args()
    args.func(args)

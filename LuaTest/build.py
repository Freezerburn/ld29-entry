import os
import subprocess
import time

cwd = os.getcwd()
lua_interpreter_path = os.path.join(cwd, "src")
lua_source_path = os.path.join(cwd, "lua")
assets_path = os.path.join(cwd, "assets")
build_path = os.path.join(cwd, "ems-build")
files_types_to_compile = (".cpp", ".c")
output_file = "index.html"

if __name__ == "__main__":
    preload_files = []
    to_compile = []
    compiled_objects = []
    header_dirs = [cwd, os.path.join(cwd, "SDL2"), os.path.join(cwd, "src")]

    if not os.path.exists(build_path):
        os.makedirs(build_path)

    for curdir, _, flist in os.walk(lua_source_path):
        for f in flist:
            preload_files.append(os.path.join("lua", f))
    for curdir, _, flist in os.walk(assets_path):
        for f in flist:
            preload_files.append(os.path.join("assets", f))

    for curdir, _, flist in os.walk(cwd):
        for f in flist:
            ext = os.path.splitext(f)[1]
            if ext in files_types_to_compile:
                to_compile.append(os.path.join(curdir, f))
                compiled_fname = os.path.splitext(f)[0] + ".bc"
                compiled_objects.append(os.path.join(build_path, compiled_fname))

    # print("preload_files = " + str(preload_files))
    # print("to_compile = " + str(to_compile))
    # print("header_dirs = " + str(header_dirs))
    to_run = ["emcc", "-x", "objective-c++", "-std=c++11", "-stdlib=libc++"]
    to_run.append("-O2")
    for f in header_dirs:
        to_run += ["-I", f]

    compile_procs = []
    num_procs_open = 0
    max_procs_open = 4
    for i in xrange(len(to_compile)):
        if not os.path.exists(compiled_objects[i]) or os.path.getmtime(to_compile[i]) > os.path.getmtime(compiled_objects[i]):
            to_run_copy = to_run[:]
            to_run_copy.append(to_compile[i])
            to_run_copy += ["-o", compiled_objects[i]]
            print("to_run_copy:%d = %s" % (i, str(to_run_copy)))
            compile_procs.append(subprocess.Popen(to_run_copy, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
            num_procs_open += 1

        while num_procs_open >= max_procs_open:
            remove_later = []
            for x in compile_procs:
                x.poll()
                if x.returncode is not None:
                    remove_later.append(x)
                    num_procs_open -= 1
            if remove_later:
                for x in remove_later:
                    compile_procs.remove(x)
            else:
                time.sleep(1)
    for x in compile_procs:
        x.wait()

    for f in preload_files:
        to_run += ["--preload-file", f]
    to_run_copy = to_run[:]
    for f in compiled_objects:
        to_run_copy.append(f)
    to_run_copy += ["-o", "index.html"]
    print("final to_run_copy = %s" % str(to_run_copy))
    x = subprocess.Popen(to_run_copy)
    x.wait()

    # for f in to_compile:
    #     to_run.append(f)
    # to_run += ["-o", output_file]
    # to_run.append("-O2")
    # for f in preload_files:
    #     to_run += ["--preload-file", f]
    # for f in header_dirs:
    #     to_run += ["-I", f]
    # # print("to_run = " + str(to_run))

    # x = subprocess.Popen(to_run)
    # x.wait()

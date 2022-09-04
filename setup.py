from pathlib import Path
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext as BuildExt
from setuptools.dist import Distribution
import subprocess
import sys
import sysconfig

lib_name = 'clip'

class BuildZigExt(BuildExt):
    def build_extension(self, ext):
        if ext.name != lib_name:
            return super().build_extension(ext)
        output = Path(self.get_ext_filename(ext.name))
        target = Path(self.get_ext_fullpath(ext.name))
        print(output, target)
        commands = [sys.executable, '-m', 'ziglang', 'build-lib', '-dynamic', '--name', output.stem, '-fPIC', '-D__sched_priority=0', '-DNDEBUG', '-I' + sysconfig.get_config_var('INCLUDEPY'), '-L' + sysconfig.get_config_var('LIBRARY'), '-L' + sysconfig.get_config_var('LIBDIR') ]
        commands.extend(ext.sources)
        output.parent.mkdir(exist_ok=True, parents=True)
        subprocess.run(commands, cwd=output.parent)
        if not output.exists():
            output = output.parent / ('lib' + output.name)
            if not output.exists():
                output = output.parent / (output.stem + '.dylib')
        if output.exists():
            if target.exists():
                target.unlink()
            else:
                target.parent.mkdir(exist_ok=True, parents=True)
            output.rename(target)
        super().build_extension(ext)

setup(
    name='pyclip',
    version='0.0.1',
    # ext_modules=[Extension(lib_name, sources=['src/pyclip.c', 'src/pyclip.zig'])],
    ext_modules=[Extension(lib_name, sources=['zig-out/lib/libpyclip.dylib'])],
    python_requires='>=3.6.5',
    setup_requires=['ziglang'],
    cmdclass={'build_ext': BuildZigExt},
)

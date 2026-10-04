#!/usr/bin/env python3
"""Run native LÖVE engine regressions in temporary, isolated game directories.
Usage: python3 tools/run_engine_tests.py --love /path/to/love [suite ...]
A working graphics/audio backend is required; see docs/engine-stability.md.
"""
import argparse
import os
import re
import shutil
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
STANDALONE = {'extension-examples', 'chart-timing', 'core-utilities', 'audio', 'compat', 'compat-controls', 'diagnostics', 'async', 'timer-lifecycle', 'menu-audio', 'script-errors', 'logger-startup', 'addon-assets', 'addon-modules', 'display', 'recoverable-errors', 'overlay-addon', 'screen-overlay'}
DEFAULT = ['extension-examples', 'chart-timing', 'core-utilities', 'syntax', 'property-setters', 'render-lifecycle', 'gameplay-flow', 'slow-frame', 'audio', 'menu-audio', 'timer-lifecycle', 'compat', 'compat-controls', 'diagnostics', 'error-screen', 'save-storage', 'script-errors', 'logger-startup', 'addon-assets', 'addon-modules', 'async', 'display', 'recoverable-errors', 'overlay-addon', 'screen-overlay']
SUCCESS = {
    'extension-examples': r'EXTENSION EXAMPLES PASSED:',
    'chart-timing': r'CHART TIMING: \d+ passed, 0 failed',
    'core-utilities': r'CORE UTILITIES: \d+ passed, 0 failed',
    'audio': r'AUDIO TESTS: \d+ passed, 0 failed',
    'timer-lifecycle': r'TIMER/TWEEN TESTS: \d+ passed, 0 failed',
    'compat': r'COMPAT PASS:', 'diagnostics': r'DIAGNOSTICS PASSED:',
    'async': r'ASYNC PASSED:', 'menu-audio': r'MENU AUDIO PASS:',
    'script-errors': r'SCRIPT DIAGNOSTICS PASS:',
    'logger-startup': r'LOGGER STARTUP PASSED:',
    'addon-assets': r'ADDON ASSETS PASS(?:ED)?:',
    'addon-modules': r'ADDON MODULES PASS(?:ED)?:',
    'compat-controls': r'COMPAT CONTROLS PASS:',
    'display': r'DISPLAY PASSED:',
    'recoverable-errors': r'RECOVERABLE ERRORS PASSED:',
    'overlay-addon': r'OVERLAY ADDON PASSED:',
    'screen-overlay': r'SCREEN OVERLAY PASSED:',
}
BOOT = '''dofile(%s)
local originalLoad=love.load
local passed,failed=0,0
function check(name,fn)
 local ok,err=xpcall(fn,debug.traceback)
 if ok then passed=passed+1;print('PASS '..name) else failed=failed+1;print('FAIL '..name..': '..err) end
end
function love.load()
 originalLoad();State.defaultTransIn,State.defaultTransOut=nil,nil;Mods.currentMod=nil
 assert(love.filesystem.load('tests/engine/'..%s..'.lua'))()
 print('RESULT '..passed..' passed / '..failed..' failed');love.event.quit(failed==0 and 0 or 1)
end
function love.update() end
function love.draw() end
function love.errorhandler(e) print('HARNESS ERROR '..tostring(e)..'\\n'..debug.traceback());return function() return 1 end end
'''
CONF = '''local Project=require 'project'
Project.company='LightEngineTests';Project.file=%s
Project.package='com.zyn.lightengine.tests.'..%s
function love.conf(t)
 t.identity=Project.package;t.modules.physics=false
 %s
end
'''

def lua_string(value):
    return '[' + '=' * 2 + '[' + str(value) + ']' + '=' * 2 + ']'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--love',default='love')
    parser.add_argument('--copy',action='store_true',help='Copy runtime once instead of using symlinks (Windows/CI)')
    parser.add_argument('--logs',type=Path,default=ROOT/'test-results')
    parser.add_argument('suites',nargs='*',choices=DEFAULT)
    args=parser.parse_args()
    suites=args.suites or DEFAULT
    missing=[suite for suite in suites if not (ROOT/'tests'/'engine'/(suite+'.lua')).is_file()]
    if missing:
        parser.error('Missing engine fixtures: '+', '.join(missing)+'. Restore the tracked tests/engine directory.')
    if not shutil.which(args.love):
        parser.error('LÖVE runtime not found: '+args.love+'. Install LÖVE 11.5 or pass --love /path/to/love.')
    args.logs.mkdir(parents=True,exist_ok=True)
    failures=[]
    with tempfile.TemporaryDirectory(prefix='light-engine-test-') as directory:
        runner=Path(directory)
        for entry in ROOT.iterdir():
            if entry.name not in {'.git','main.lua','conf.lua','test-results','release','android','docs','tools','.github','.ci','.superpowers','mods','addons','__pycache__'}:
                if args.copy:
                    if entry.is_dir(): shutil.copytree(entry,runner/entry.name)
                    else: shutil.copy2(entry,runner/entry.name)
                else:
                    (runner/entry.name).symlink_to(entry,target_is_directory=entry.is_dir())
        for suite in suites:
            fixture=ROOT/'tests'/'engine'/(suite+'.lua')
            if suite in STANDALONE:
                (runner/'main.lua').write_text(fixture.read_text(encoding='utf-8'),encoding='utf-8')
            else:
                (runner/'main.lua').write_text(BOOT % (lua_string(ROOT/'main.lua'),lua_string(suite)),encoding='utf-8')
            window='t.window.width=64;t.window.height=64' if suite in {'core-utilities','audio','menu-audio','timer-lifecycle','async'} else 't.modules.window=false'
            (runner/'conf.lua').write_text(CONF % (lua_string(suite),lua_string(suite),window),encoding='utf-8')
            env=os.environ.copy();env['ENGINE_ROOT']=str(ROOT)
            logfile=args.logs/(suite+'.log')
            try:
                with logfile.open('w',encoding='utf-8') as log:
                    result=subprocess.run([args.love,str(runner)],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
                code=result.returncode
            except subprocess.TimeoutExpired:
                code=124
            # A detached GUI launcher returning zero is not test completion.
            # Require the fixture's final marker as well as its exit status.
            output=logfile.read_text(encoding='utf-8',errors='replace')
            if code == 0 and not re.search(SUCCESS.get(suite,r'RESULT \d+ passed / 0 failed'),output):
                code=1
                with logfile.open('a',encoding='utf-8') as log:
                    log.write('\nMissing native test completion marker.\n')
            print(f'{suite}: exit {code} ({logfile})',flush=True)
            if code: failures.append(suite)
    if failures: print('FAILED: '+', '.join(failures))
    return bool(failures)

if __name__=='__main__': raise SystemExit(main())

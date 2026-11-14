import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description='Capture a repeatable native scene on an engine checkout. Use a fresh process per trial.')
    parser.add_argument('--engine', type=Path, default=ROOT)
    parser.add_argument('--love', default='love')
    parser.add_argument('--song', default='bopeebo')
    parser.add_argument('--difficulty', default='normal')
    parser.add_argument('--seconds', type=float, default=30)
    parser.add_argument('--device', required=True)
    parser.add_argument('--run', default='trial')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error('--seconds must be positive')
    engine = args.engine.resolve()
    fingerprint = hashlib.sha256()
    for path in sorted((engine / 'assets').rglob('*')):
        if path.is_file() and 'images/loading/' not in path.as_posix() and path.name not in {'Loading.ttf', 'LoadingDot.ttf'}:
            fingerprint.update(str(path.relative_to(engine)).encode())
            with path.open('rb') as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    fingerprint.update(block)
    args.output = args.output.resolve()
    options = {'song': args.song, 'difficulty': args.difficulty, 'device': args.device, 'run': args.run, 'cache': 'fresh-process', 'content': fingerprint.hexdigest()}
    def lua(value):
        return '[==[' + str(value) + ']==]'
    with tempfile.TemporaryDirectory(prefix='light-benchmark-') as directory:
        runner = Path(directory)
        for entry in engine.iterdir():
            if entry.name not in {'.git', 'main.lua', 'conf.lua', 'test-results', 'release', 'android', 'docs', 'tools', '.github', '.ci', '.superpowers', 'mods', 'addons', '__pycache__'}:
                (runner / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
        (runner / 'conf.lua').write_text("function love.conf(t) t.identity='com.zyn.lightengine.benchmark';t.window.width=1280;t.window.height=720 end")
        script = f'''dofile({lua(engine / 'main.lua')})
local B=assert(loadfile({lua(ROOT / 'funkin/backend/benchmark.lua')}))()
local oldLoad,oldUpdate,oldDraw=love.load,love.update,love.draw
local elapsed,done=0,false
function love.load()
 oldLoad()
 State.defaultTransIn,State.defaultTransOut=nil,nil
 Mods.currentMod=nil
 love.autoPause=false
 if os.getenv("SDL_VIDEODRIVER")=="offscreen" then love.window.hasFocus=function()return true end end
 ClientPrefs.data.autoPause=false
 ClientPrefs.data.botplayMode=true
 ClientPrefs.data.performanceCapture=false
 local opts=(loxreq 'lib.json').decode({lua(json.dumps(options))})
 B.start(opts)
 game.switchState(LoadState(PlayState(false,opts.song,opts.difficulty)),true)
end
function love.update(dt)
 B.update()
 oldUpdate(dt)
 local state=game.getState()
 if state and state._postCreated and not state._prepareJob then B.ready();elapsed=elapsed+dt end
 if elapsed>={args.seconds} and not done then
  done=true
  local report=B.finish(false)
  report.context.sample_seconds={args.seconds}
  local file=assert(io.open({lua(args.output)},'w'));file:write(JSON.encode(report,true));file:close()
  print('BENCHMARK COMPLETE');love.event.quit(0)
 end
end
function love.draw() B.frame();oldDraw() end
function love.errorhandler(error)
 print('BENCHMARK ERROR '..tostring(error)..'\\n'..debug.traceback())
 return function()return 1 end
end
'''
        (runner / 'main.lua').write_text(script)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run([args.love, str(runner)], timeout=args.seconds + 180)
        return result.returncode

if __name__ == '__main__':
    raise SystemExit(main())

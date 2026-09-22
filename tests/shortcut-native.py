import json,os,sys,subprocess,tempfile,time,shutil
from pathlib import Path
project=Path(__file__).resolve().parents[1]
connection=json.loads(Path(sys.argv[1]).read_text());assert connection['HYPRLAND_INSTANCE_SIGNATURE']!=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE') and Path(connection['XDG_RUNTIME_DIR']).is_relative_to('/tmp')
env=os.environ|connection|{'QT_QPA_PLATFORM':'wayland','QT_QPA_PLATFORMTHEME':'','QT_QUICK_BACKEND':'software','OMACARDS_FIXTURE':str(project/'tests/fixture.json')}
def ctl(*args):
 p=subprocess.run(['hyprctl',*args],env=env,text=True,capture_output=True,timeout=8);assert p.returncode==0,p.stderr;return p.stdout.strip()
ctl('eval','hl.config({input={resolve_binds_by_sym=true},plugin={hyprflip={duration_ms=139}}});hl.bind("SUPER + CTRL + ALT + F10",function() hl.config({plugin={hyprflip={duration_ms=137}}}) end,{description="Capture test counter"})')
with tempfile.TemporaryDirectory(prefix='oc-key-') as directory:
 root=Path(directory)
 for name in ('Ui','Commons'):(root/name).symlink_to('/usr/share/omarchy/shell'/Path(name))
 (root/'Cards').mkdir()
 for source in project.glob('*.qml'):shutil.copy2(source,root/'Cards'/source.name)
 shutil.copy2(project/'tests/shortcut-native.qml',root/'shell.qml')
 with (project/'tests/shortcut-native.log').open('w') as log:
  process=subprocess.Popen(['quickshell','-p',str(root),'--no-color'],env=env,stdout=log,stderr=log)
  try:
   def ipc(action):
    p=subprocess.run(['quickshell','-p',str(root),'ipc','call','capturetest',action],env=env,text=True,capture_output=True,timeout=5)
    return p.stdout.strip()
   deadline=time.monotonic()+10
   while time.monotonic()<deadline:
    try:
     if json.loads(ipc('status'))['opened']:break
    except (ValueError,KeyError):pass
    time.sleep(.1)
   armed=ipc('arm');assert armed=='ok',armed
   time.sleep(.4)
   assert json.loads(ipc('status'))['recording']
   subprocess.run(['wtype','-M','logo','-M','ctrl','-M','alt','-k','F10','-m','alt','-m','ctrl','-m','logo'],env=env,check=True)
   time.sleep(.25)
   state=json.loads(ipc('status'));assert state['key']=='F10' and state['mask']==76,state
   assert json.loads(ctl('-j','getoption','plugin:hyprflip:duration_ms'))['int']==139,'Global action fired during recording'
   ipc('hide');time.sleep(.25)
   subprocess.run(['wtype','-M','logo','-M','ctrl','-M','alt','-k','F10','-m','alt','-m','ctrl','-m','logo'],env=env,check=True)
   time.sleep(.3)
   count=json.loads(ctl('-j','getoption','plugin:hyprflip:duration_ms'))['int'];assert count==137,(count,ipc('status'))
   print('PASS real Wayland key capture blocks an existing desktop shortcut and releases on close')
  finally:
   process.terminate();process.wait(timeout=5)
   ctl('eval','hl.unbind("SUPER + CTRL + ALT + F10")')

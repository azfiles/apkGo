"""Bundle the verified preview, editable source, models, and evidence."""
from pathlib import Path
import hashlib,re,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2]
VERSION=re.search(r'^config/version="([^"]+)"$',(ROOT/'maze3d/project.godot').read_text(),re.M).group(1)
RELEASE=ROOT/'build/maze3d/release';RELEASE.mkdir(parents=True,exist_ok=True)
for old in RELEASE.iterdir():
    if old.is_file():old.unlink()
apk=ROOT/f'build/maze3d/output/Pipi-Maze-Ruins-{VERSION}.apk'
shutil.copy2(apk,RELEASE/apk.name)

def archive(name,files):
    with zipfile.ZipFile(RELEASE/name,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
        for p in files:
            if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and not p.name.endswith('.blend1'):
                z.write(p,p.relative_to(ROOT))
files=[]
for rel in ['maze3d','scripts/maze3d','model-source/maze3d','docs/maze3d']:
    files.extend((ROOT/rel).rglob('*'))
files.extend([ROOT/'signing/demo-signing.p12.base64',ROOT/'README.md',ROOT/'docs/PROJECTS.md',ROOT/'.github/workflows/maze3d.yml',ROOT/'.github/workflows/verify.yml'])
archive(f'Pipi-Maze-Ruins-{VERSION}-Source.zip',files)
archive('Pipi-Maze-Ruins-3D-Models.zip',list((ROOT/'maze3d/assets/models').glob('*.glb'))+list((ROOT/'model-source/maze3d').glob('*.blend'))+[ROOT/'scripts/maze3d'/name for name in ['model_assets.py','brown_model.py','starbridge_models.py','export_models.py','starbridge_level.py']]+[ROOT/'maze3d/assets/model_catalog.json',ROOT/'docs/maze3d/MODELING.md',ROOT/'docs/maze3d/BROWN.md'])
archive(f'Brown-Character-{VERSION}.zip',[ROOT/'maze3d/assets/models/brown.glb',ROOT/'model-source/maze3d/brown_character.blend',ROOT/'model-source/maze3d/reference/brown-official.png',ROOT/'scripts/maze3d/brown_model.py',ROOT/'maze3d/scripts/character.gd',ROOT/'docs/maze3d/BROWN.md']+list((ROOT/'docs/maze3d/brown').glob('*')))
report_names=['import.txt','data.txt','model.txt','scene.txt','jump.txt','character.txt','capture.txt','art-capture.txt','starbridge-capture.txt','starbridge-models.txt','model-export.txt','source-contract.txt','build.txt','standalone.txt','release-startup.txt','apk-data.txt','android.txt','brown-model.txt','scenery-models.txt']
archive('Pipi-Maze-Ruins-Verification.zip',[ROOT/'build/maze3d/reports'/name for name in report_names]+list((ROOT/'build/maze3d/android').rglob('*'))+list((ROOT/'build/maze3d/starbridge-screens').rglob('*'))+[ROOT/'build/maze3d/apk-report.txt'])
for p in (ROOT/'docs/maze3d/screenshots').glob('*.png'):shutil.copy2(p,RELEASE/p.name)
for p in (ROOT/'docs/maze3d/brown').glob('*.png'):shutil.copy2(p,RELEASE/('Brown-'+p.name))
shutil.copy2(ROOT/'docs/maze3d/BROWN.md',RELEASE/'BROWN.md')
shutil.copy2(ROOT/'docs/maze3d/ART.md',RELEASE/'ART.md')
shutil.copy2(ROOT/'maze3d/assets/icon.png',RELEASE/f'Brown-App-Icon-{VERSION}.png')
shutil.copy2(ROOT/'docs/maze3d/MODELING.md',RELEASE/'MODELING.md')
shutil.copy2(ROOT/'docs/maze3d/DATA_LEVEL_VERIFICATION.md',RELEASE/'DATA_LEVEL_VERIFICATION.md')
shutil.copy2(ROOT/'maze3d/README.md',RELEASE/'README.md')
shutil.copy2(ROOT/'docs/maze3d/RELEASE_NOTES.md',RELEASE/'RELEASE_NOTES.md')
(RELEASE/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(RELEASE.iterdir()) if p.is_file()))
print('Packaged',len(list(RELEASE.iterdir())),'release artifacts')

"""Prepare the stock Godot Web shell using the same translation catalogs as the game."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
keys=['Loading flight systems…','Unable to load the game. Reload to try again.','Your browser does not support the canvas tag.']
catalogs={locale:{key:json.loads((root/'localization'/f'{locale}.json').read_text())[key] for key in keys} for locale in ['en','id']}
html=(root/'templates/web_shell_base.html').read_text()
html=html.replace('<progress id="status-progress"></progress>','<div id="loading-label" role="status"></div><progress id="status-progress"></progress>')
html=html.replace('<noscript>\n\t\t\tYour browser does not support JavaScript.','<noscript>\n\t\t\tEnable JavaScript to play / Aktifkan JavaScript untuk bermain.')
html=html.replace('const GODOT_CONFIG =', '''const LOADER_CATALOGS = '''+json.dumps(catalogs,ensure_ascii=False)+''';
let loaderLocale = 'en';
try { loaderLocale = localStorage.getItem('arena-dash-language') === 'id' ? 'id' : 'en'; } catch (error) {}
document.documentElement.lang = loaderLocale;
function loaderText(key) { return LOADER_CATALOGS[loaderLocale][key] || key; }
document.getElementById('loading-label').textContent = loaderText('Loading flight systems…');
document.getElementById('canvas').textContent = loaderText('Your browser does not support the canvas tag.');
const GODOT_CONFIG =''')
a=html.index('\t\tif (err instanceof Error) {',html.index('function displayFailureNotice'))
b=html.index("\n\t\tsetStatusMode('notice');",a)
html=html[:a]+"\t\tsetStatusNotice(loaderText('Unable to load the game. Reload to try again.'));"+html[b:]
html=html.replace("statusProgress.style.display = mode === 'progress' ? 'block' : 'none';","statusProgress.style.display = mode === 'progress' ? 'block' : 'none';\n\t\tdocument.getElementById('loading-label').style.display = mode === 'progress' ? 'block' : 'none';")
html=html.replace('</style>','''#loading-label {position:absolute;bottom:15%;font:20px/1.4 Arial,sans-serif;color:#acbddd;text-align:center;padding:16px;}
</style>''',1)
(root/'templates/web_shell.html').write_text(html)
print('Web loading shell generated from EN/ID catalogs')

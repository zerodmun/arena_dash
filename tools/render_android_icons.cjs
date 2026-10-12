// Render the supplied SVG filters with librsvg; preserve transparent glow pixels.
const fs = require('fs');
const path = require('path');
const os = require('os');
let sharp;
try { sharp = require('sharp'); } catch {
  sharp = require(process.env.ARENA_ICON_SHARP_PATH || path.join(os.homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp'));
}
async function main() {
  const directory = path.join(__dirname, '../assets/android_icons');
  if (process.argv[2]==='--verify') {
    for (const [name,source] of [['icon.webp','launcher_192.png'],['icon_foreground.webp','adaptive_foreground.png'],['icon_background.webp','adaptive_background.png']]) {
      const actual=await sharp(path.join(process.argv[3],name)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      const expected=await sharp(path.join(directory,source)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      if(actual.info.width!==expected.info.width || actual.info.height!==expected.info.height || !actual.data.equals(expected.data)) throw Error(`Packaged launcher pixels differ: ${name}`);
    }
    console.log('PACKAGED ICON PASS: all three xxxhdpi layers match source pixels');
    return;
  }
  const foreground = await sharp(path.join(directory, 'adaptive_foreground.svg')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const background = await sharp(path.join(directory, 'adaptive_background.svg')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let radius = 0;
  for (let y=0;y<432;y++) for(let x=0;x<432;x++) {
    const offset=(y*432+x)*4;
    if(background.data[offset+3]!==255) throw Error('Background is not opaque');
    if(foreground.data[offset+3]>2) radius=Math.max(radius,Math.hypot(x+.5-216,y+.5-216));
  }
  if(radius>132) throw Error(`Aircraft glow exceeds safe zone: ${radius}`);
  const fg = await sharp(foreground.data,{raw:foreground.info}).png().toBuffer();
  const bg = await sharp(background.data,{raw:background.info}).png().toBuffer();
  const combined=await sharp(bg).composite([{input:fg}]).png().toBuffer();
  const outputs=[['adaptive_foreground.png',fg],['adaptive_background.png',bg]];
  for(const size of [48,72,96,144,192]) {
    outputs.push([`launcher_${size}.png`, await sharp(combined).extract({left:72,top:72,width:288,height:288}).resize(size,size).png().toBuffer()]);
  }
  for(const [name,buffer] of outputs) fs.writeFileSync(path.join(directory,name),buffer);
  console.log(`SVG FILTER ICON PASS: original artwork, safe radius ${radius.toFixed(2)} / 132px`);
}
main().catch(error=>{console.error(error.message);process.exitCode=1});

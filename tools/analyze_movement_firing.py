#!/usr/bin/env python3
"""Summarize retained device logs without treating event injection as visual QA."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent.parent/'qa/movement-fire-qa'
result={}
for name in ['baseline-diagnostic','fixed-matrix','fixed-equipment']:
    path=root/(name+'-logcat.txt')
    if not path.exists():continue
    text=path.read_text(errors='replace');hits=[];equipment=[];controls=[];case_launches={};active_case=None
    for line in text.splitlines():
        if 'EQUIPMENT_CASE_START ' in line:
            active_case=line.split('EQUIPMENT_CASE_START ',1)[1].strip();case_launches[active_case]=0
        if 'BULLET_LAUNCH {' in line and active_case is not None:case_launches[active_case]+=1
        if 'EQUIPMENT_CASE_END ' in line:active_case=None
        if 'BULLET_IMPACT ' in line:hits.append(json.loads(line[line.index('{'):]))
        if 'EQUIPMENT_CASE_END ' in line:equipment.append(json.loads(line[line.index('{'):]))
        if 'PERF {' in line:controls.append(json.loads(line[line.index('{'):])['controls'])
    result[name]={
        'completed_scenarios':sum('CASE_END ' in l and 'EQUIPMENT_CASE_END ' not in l for l in text.splitlines()),
        'launches':text.count('BULLET_LAUNCH {'),
        'blocked_launches':text.count('BULLET_LAUNCH_BLOCKED '),
        'impacts':len(hits),
        'age_zero_terrain_impacts':sum(h['layer']==1 and h['age']==0 for h in hits),
        'player_impacts':sum(h['layer']==2 for h in hits),
        'invalid_layer_impacts':sum(h['layer'] not in [1,4] for h in hits),
        'equipment_combinations':len(equipment),
        'equipment_cases_with_new_projectiles':sum(n>0 for n in case_launches.values()),
        'equipment_launch_counts':case_launches,
        'equipment_endpoints_moving_and_firing':sum(e['fire'] and e['movement']>1 for e in equipment),
        'simultaneous_control_samples':sum(c['fire_pressed'] and c['joystick_pressed'] for c in controls),
        'godot_errors':[l for l in text.splitlines() if 'E godot' in l or 'FATAL EXCEPTION' in l],
    }
(root/'results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))

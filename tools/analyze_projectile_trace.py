#!/usr/bin/env python3
"""Verify projectile lifecycle/trajectory/impact causality from retained QA traces."""
import collections,json,math,sys
from pathlib import Path
path=Path(sys.argv[1]);shots={};impacts={};effects=[];errors=[];counts=collections.Counter();weapons=collections.Counter();aircraft=collections.Counter();moves=0;initial_penetrations=[];fires={};completed={};event_shots=collections.defaultdict(list);blocked=collections.Counter()
for line in path.open():
 r=json.loads(line);kind=r['event'];counts[kind]+=1
 if kind=='fire':
  if r['event_id'] in fires:errors.append(['duplicate_fire',r['event_id']])
  fires[r['event_id']]=r
 elif kind=='fire_complete':completed[r['event_id']]=r
 elif kind=='spawn_blocked':blocked[r['event_id']]+=1
 elif kind=='spawn':
  if r['id'] in shots:errors.append(['duplicate_spawn',r['id']])
  if 'event_id' in r:event_shots[r['event_id']].append(r)
  shots[r['id']]={'spawn':r,'last':r,'end':None};weapons[r['weapon']]+=1;aircraft[r['aircraft']]+=1
  if r['layer']!=0 or r['mask']!=5:errors.append(['collision_filter',r['id']])
  if math.dist(r['position'],r['player'])<48:errors.append(['inside_owner',r['id']])
 elif kind=='move':
  shot=shots.get(r['id'])
  if not shot:errors.append(['move_without_spawn',r['id']]);continue
  if shot['end']:errors.append(['move_after_end',r['id']])
  origin=shot['spawn']['position'];direction=shot['spawn']['direction'];actual=[r['position'][i]-origin[i] for i in range(2)]
  # All motion must remain on the original world-space trajectory. Collision
  # boundaries can shorten a final step, but cannot add aircraft velocity.
  if abs(actual[0]*direction[1]-actual[1]*direction[0])>.1:errors.append(['trajectory_changed',r['id']])
  shot['last']=r;moves+=1
 elif kind=='impact':
  if r['id'] in impacts:errors.append(['duplicate_impact',r['id']])
  impacts[r['id']]=r
  if not r['actual_overlap']:errors.append(['unverified_contact',r['id']])
  if r['target_layer'] not in [1,4]:errors.append(['invalid_target_layer',r['id']])
  if r['target']==r['owner']:errors.append(['self_impact',r['id']])
  if 'contact' in r and math.dist(r['contact'],r['center'])>14.2:
   # A query beginning inside a collider reports a point on that collider,
   # which need not lie on the projectile perimeter. Retain these separately;
   # only an unadvanced pose with a verified overlap qualifies.
   shot=shots.get(r['id'])
   if shot and (r.get('contact_kind')=='initial_overlap' or (r['age']==0 and math.dist(r['center'],shot['spawn']['position'])<.001)):
    initial_penetrations.append(r['id'])
   else:errors.append(['contact_beyond_footprint',r['id']])
 elif kind=='effect' and r.get('projectile_id',0):effects.append(r)
 elif kind=='despawn':
  shot=shots.get(r['id'])
  if not shot:errors.append(['end_without_spawn',r['id']]);continue
  if shot['end']:errors.append(['duplicate_end',r['id']])
  shot['end']=r
  if r['reason']=='impact' and r['id'] not in impacts:errors.append(['impact_without_contact',r['id']])
for event_id,spawned in event_shots.items():
 fire=fires.get(event_id)
 if not fire:errors.append(['spawn_without_authorized_fire',event_id]);continue
 indices=[r['pattern_index'] for r in spawned]
 if len(indices)!=len(set(indices)):errors.append(['duplicate_pattern_index',event_id])
 for shot in spawned:
  i=shot['pattern_index']
  if i<0 or i>=fire['expected_count']:errors.append(['invalid_pattern_index',shot['id']]);continue
  spec=fire['pattern'][i];angle=spec['angle'];hx,hy=fire['heading']
  expected_dir=[hx*math.cos(angle)-hy*math.sin(angle),hx*math.sin(angle)+hy*math.cos(angle)]
  expected_pos=[fire['muzzle'][0]-hy*spec['offset'],fire['muzzle'][1]+hx*spec['offset']]
  if shot['owner']!=fire['owner'] or shot['weapon']!=fire['weapon']:errors.append(['event_owner_weapon_mismatch',shot['id']])
  if math.dist(shot['direction'],expected_dir)>.001:errors.append(['pattern_direction_mismatch',shot['id']])
  if math.dist(shot['position'],expected_pos)>.01:errors.append(['pattern_origin_mismatch',shot['id']])
  if abs(math.hypot(*shot['velocity'])-fire['speed'])>.01:errors.append(['initial_speed_mismatch',shot['id']])
for event_id,fire in fires.items():
 end=completed.get(event_id)
 if not end:errors.append(['incomplete_fire',event_id]);continue
 if len(event_shots[event_id])+blocked[event_id]!=fire['expected_count']:errors.append(['fire_count_mismatch',event_id])
 if len(event_shots[event_id])!=end['spawned'] or blocked[event_id]!=end['blocked']:errors.append(['fire_result_mismatch',event_id])
for effect in effects:
 hit=impacts.get(effect['projectile_id'])
 if not hit:errors.append(['effect_without_impact',effect['projectile_id']]);continue
 if 'contact' in hit and math.dist(effect['position'],hit['contact'])>.001:errors.append(['effect_wrong_position',effect['projectile_id']])
result={'file':str(path),'authorized_firing_events':len(fires),'events':dict(counts),'shots':len(shots),'movement_samples':moves,'impacts':len(impacts),'projectile_effects':len(effects),'weapons':dict(weapons),'aircraft':dict(aircraft),'errors':errors,'initial_penetrations':initial_penetrations,'passed':not errors}
path.with_suffix('.analysis.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2));sys.exit(0 if not errors else 1)

from pathlib import Path
p=Path('frontend/user/lib/profile_pages/subscriptions.dart')
s=p.read_text()
open_count=0
negline=None
for i,line in enumerate(s.splitlines(),start=1):
    open_count += line.count('{') - line.count('}')
    if open_count<0 and negline is None:
        negline=i

print('negative_line:', negline)
print('final_balance:', open_count)
# print context around negative line if present
if negline:
    lines=s.splitlines()
    start=max(0,negline-5)
    end=min(len(lines), negline+5)
    print('\n---context---')
    for ln in range(start,end):
        print(f'{ln+1}: {lines[ln]}')
else:
    lines=s.splitlines()
    print('\n---last 40 lines---')
    for ln in range(max(0,len(lines)-40),len(lines)):
        print(f'{ln+1}: {lines[ln]}')

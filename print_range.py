import sys 
from pathlib import Path 
path=Path(sys.argv[1]) 
lines=path.read_text().splitlines() 
start=int(sys.argv[2]) 
end=int(sys.argv[3]) 
for i in range(start, min(end, len(lines))): 
    print(f'{i+1}: {lines[i]}') 

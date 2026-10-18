using System;
using System.Collections.Generic;

namespace PipiMaze
{
    [Serializable] public struct Cell : IEquatable<Cell>
    {
        public int x, y;
        public Cell(int x, int y) { this.x=x; this.y=y; }
        public bool Equals(Cell b) => x==b.x && y==b.y;
        public override bool Equals(object b) => b is Cell c && Equals(c);
        public override int GetHashCode() => x*397 ^ y;
        public static Cell operator +(Cell a, Cell b) => new Cell(a.x+b.x,a.y+b.y);
    }
    [Serializable] public class Challenge { public Cell cell, axis; public string kind; public float height, span; }
    [Serializable] public struct Position { public float x,y,z; }
    [Serializable] public class Scenery { public string asset; public Position position; public float rotation_y, scale=1; public bool collisions=true; }
    [Serializable] public class Region { public string name,floor; public int[] bounds; }
    [Serializable] public class EnvironmentStyle { public string background,fog,water; }
    [Serializable] public class Level
    {
        public int version,seed;
        public string id,title,subtitle,difficulty;
        public float tile_size=4,bridge_rotation_y;
        public string[] grid;
        public Cell start,goal;
        public Cell[] beacons,motes;
        public int[] elevated_motes;
        public Challenge[] challenges;
        public Scenery[] scenery;
        public Region[] regions;
        public EnvironmentStyle environment;
        public int Width => grid.Length;
        public static readonly string[] Ids={"first_light","echo_halls","sleeping_stars","starbridge_garden"};
        static readonly Cell[] Directions={new Cell(0,-1),new Cell(1,0),new Cell(0,1),new Cell(-1,0)};
        public char Surface(Cell c) => c.x>=0 && c.y>=0 && c.x<Width && c.y<Width ? grid[c.y][c.x] : '#';
        public bool Open(Cell c) => Surface(c)=='.' || Surface(c)=='=';
        public Challenge Hazard(Cell c) { foreach(var h in challenges) if(h.cell.Equals(c)) return h; return null; }
        public bool Elevated(int index) => Array.IndexOf(elevated_motes,index)>=0;
        public List<Cell> Path(Cell from,Cell target)
        {
            var route=new List<Cell>(); if(!Open(from)||!Open(target)) return route;
            var previous=new Dictionary<Cell,Cell>{{from,from}};var queue=new Queue<Cell>();queue.Enqueue(from);
            while(queue.Count>0 && !previous.ContainsKey(target))
            {
                Cell c=queue.Dequeue();foreach(var d in Directions){Cell n=c+d;if(Open(n)&&!previous.ContainsKey(n)){previous[n]=c;queue.Enqueue(n);}}
            }
            if(!previous.ContainsKey(target))return route;
            for(Cell c=target;!c.Equals(from);c=previous[c])route.Add(c);route.Reverse();return route;
        }
        public void Validate()
        {
            if(version!=1 || grid==null || Width<5 || Width>41 || tile_size!=4 || beacons==null || beacons.Length!=3 || motes==null || motes.Length==0)
                throw new InvalidOperationException("Invalid level header: "+id);
            for(int y=0;y<Width;y++)
            {
                if(grid[y].Length!=Width)throw new InvalidOperationException("Non-square grid");
                for(int x=0;x<Width;x++)
                {
                    char s=grid[y][x];if("#.~=".IndexOf(s)<0)throw new InvalidOperationException("Invalid surface");
                    if((x==0||y==0||x==Width-1||y==Width-1)&&s!='#')throw new InvalidOperationException("Open outer boundary");
                }
            }
            var used=new HashSet<Cell>();
            var objectives=new List<Cell>{start,goal};objectives.AddRange(beacons);objectives.AddRange(motes);
            foreach(var c in objectives) if(!Open(c)||!used.Add(c)||(!c.Equals(start)&&Path(start,c).Count==0)) throw new InvalidOperationException("Unreachable or overlapping objective");
            foreach(var c in challenges)
                if(!Open(c.cell)||used.Contains(c.cell)||(c.kind!="gap"&&c.kind!="hurdle")||Math.Abs(c.axis.x)+Math.Abs(c.axis.y)!=1||c.height<=0||c.height>.75f||c.span<=0||c.span>1.4f)
                    throw new InvalidOperationException("Invalid jump challenge");
            foreach(int i in elevated_motes)if(i<0||i>=motes.Length)throw new InvalidOperationException("Invalid elevated star");
        }
    }
}

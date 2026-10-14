import com.alex.schulteflow.GameSession;
import java.util.*;
public class GameSessionTest {
 static int checks; static void check(boolean ok){checks++;if(!ok)throw new AssertionError("check "+checks);}
 public static void main(String[] args){
 for(int size=3;size<=5;size++){
 GameSession g=new GameSession(size,new Random(size));int[] board=g.board();Set<Integer>s=new HashSet<>();for(int n:board)s.add(n);check(s.size()==size*size);check(Collections.min(s)==1);check(Collections.max(s)==size*size);
 check(g.tap(1,0)==GameSession.Hit.IGNORED);g.start(100);check(g.tap(2,150)==GameSession.Hit.WRONG);check(g.next()==1&&g.mistakes()==1);check(g.tap(1,200)==GameSession.Hit.CORRECT);check(g.tap(1,210)==GameSession.Hit.IGNORED);g.pause(300);check(g.elapsed(10000)==200);check(g.tap(2,10000)==GameSession.Hit.IGNORED);
 g=GameSession.restore(size,g.board(),g.next(),g.mistakes(),g.elapsed(10000));check(g.state()==GameSession.State.PAUSED);check(g.next()==2&&g.mistakes()==1);g.resume(10000);for(int n=2;n<=size*size;n++)check(g.tap(n,10100)==(n==size*size?GameSession.Hit.COMPLETE:GameSession.Hit.CORRECT));check(g.elapsed(99999)==300);check(g.completed()==size*size);
 try{GameSession.restore(size,new int[size*size],1,0,0);throw new AssertionError();}catch(IllegalArgumentException expected){checks++;}
 }
 System.out.println("TOTAL "+checks+" MODEL CHECKS PASS");
 }
}

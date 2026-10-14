package com.alex.schulteflow;
import java.util.Random;
/** Monotonic, independently testable round state. */
public final class GameSession {
 public enum State { READY, RUNNING, PAUSED, FINISHED }
 public enum Hit { IGNORED, WRONG, CORRECT, COMPLETE }
 private final int size; private final int[] board;
 private int next=1, mistakes=0; private long accrued=0, started=0;
 private State state=State.READY;
 public GameSession(int size, Random random) {
  if(size<3||size>5)throw new IllegalArgumentException("size");
  this.size=size;board=new int[size*size];for(int i=0;i<board.length;i++)board[i]=i+1;
  for(int i=board.length-1;i>0;i--){int j=random.nextInt(i+1),t=board[i];board[i]=board[j];board[j]=t;}
 }
 public static GameSession restore(int size,int[] values,int next,int mistakes,long elapsed){
  GameSession g=new GameSession(size,new Random());
  if(values.length!=size*size||next<1||next>values.length||mistakes<0||elapsed<0)throw new IllegalArgumentException("snapshot");
  boolean[] seen=new boolean[values.length+1];
  for(int n:values){if(n<1||n>values.length||seen[n])throw new IllegalArgumentException("board");seen[n]=true;}
  System.arraycopy(values,0,g.board,0,values.length);g.next=next;g.mistakes=mistakes;g.accrued=elapsed;g.state=State.PAUSED;return g;
 }
 public void start(long now){if(state==State.READY){started=now;state=State.RUNNING;}}
 public void pause(long now){if(state==State.RUNNING){accrued=elapsed(now);state=State.PAUSED;}}
 public void resume(long now){if(state==State.PAUSED){started=now;state=State.RUNNING;}}
 public long elapsed(long now){return accrued+(state==State.RUNNING?Math.max(0,now-started):0);}
 public Hit tap(int n,long now){
  if(state!=State.RUNNING||n<next||n>board.length)return Hit.IGNORED;
  if(n!=next){mistakes++;return Hit.WRONG;}
  next++;if(next>board.length){accrued=elapsed(now);state=State.FINISHED;return Hit.COMPLETE;}return Hit.CORRECT;
 }
 public State state(){return state;}public int size(){return size;}public int count(){return board.length;}
 public int next(){return next;}public int mistakes(){return mistakes;}public int completed(){return Math.min(next-1,board.length);}
 public int[] board(){return board.clone();}
}

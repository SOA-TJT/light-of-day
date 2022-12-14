$(document).ready(function(){
  $(".alert").fadeTo(2000,500).slideUp(500, function() {
    $(".alert").slideUp(500);
  });
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
});

//  pomodoro

const buttonPlay=document.getElementById('buttonPlay');
const playIcon=document.getElementById('playIcon');
const buttonReset=document.getElementById('buttonReset');
const leftTime=document.getElementById('leftTime');

// const breakTime = document.getElementById('labelSessionBreak');

const workTitle = document.getElementById('work-title');
const restTitle = document.getElementById('rest-title');
const workTime = document.getElementById('work-period-time');
const restTime = document.getElementById('rest-period-time');
const workDecrease = document.getElementById('work-decrease');
const workIncrease = document.getElementById('work-increase');
const restDecrease = document.getElementById('rest-decrease');
const restIncrease = document.getElementById('rest-increase');

let isPlay=false;
let interval;
let isWork=true;
const arrayTime = leftTime.innerText.split(":");
let timeLeft = parseInt(arrayTime[0] * 60) + parseInt(arrayTime[1]); 

buttonReset.addEventListener('click', ()=>{
  reset();
})

function reset(){
  isWork=true;
  isPlay=false;
  timeLeft=parseInt(workTime.innerText)*60; 
  const minutesAndSeconds = convertSeconds(timeLeft);
  leftTime.innerText = `${('0'+minutesAndSeconds.minutes).slice(-2)}:${('0'+minutesAndSeconds.seconds).slice(-2)}`;
  workTitle.classList.remove('work-active');
  restTitle.classList.remove('rest-active'); 
  if(playIcon.classList.contains('fa-circle-pause')){
   
    playIcon.classList.add('fa-circle-play');
    playIcon.classList.remove('fa-circle-pause');

  }
}

buttonPlay.addEventListener('click',()=>{
  console.log(timeLeft);
  
  isPlay=!isPlay;
  if(isPlay){
    if((!workTitle.classList.contains('work-active'))&& !restTitle.classList.contains('rest-active')){
      workTitle.classList.add('work-active');
    }
    
    playIcon.classList.add('fa-circle-pause');
    playIcon.classList.remove('fa-circle-play');
    if(interval){
      clearInterval(interval)
    }
    interval = setInterval(handleTime,1000);
    function handleTime(){
      if(timeLeft<=0){
          if(isWork){
              timeLeft=parseInt(restTime.innerText)*60;
              workTitle.classList.remove('work-active');
              restTitle.classList.add('rest-active'); 
          }
          else{
              safe_time();
              timeLeft=parseInt(workTime.innerText)*60; 
              workTitle.classList.add('work-active');
              restTitle.classList.remove('rest-active'); 
          }
          isWork=!isWork;
      }
      else if(!isPlay){
        clearInterval(interval);
      }
      else if(timeLeft>0 ){
        timeLeft--;
        const minutesAndSeconds = convertSeconds(timeLeft);
        leftTime.innerText = `${('0'+minutesAndSeconds.minutes).slice(-2)}:${('0'+minutesAndSeconds.seconds).slice(-2)}`;
      }


    }
  }
  else{
    playIcon.classList.add('fa-circle-play');
    playIcon.classList.remove('fa-circle-pause');
  }
})

function convertSeconds(seconds) {
    return {
        minutes: Math.floor(seconds / 60), // nombre de minutes
        seconds: seconds % 60 // nombre de secondes
    }
}


function handleIncrease(currentDom,isIncrease){
  value=currentDom.innerText;
  if(value>1){
    value=parseInt(value)+isIncrease;
    currentDom.innerText=value;
  }
  reset();
}

// workTime.innerText="123";
workIncrease.addEventListener('click',()=>{
  handleIncrease(workTime,1);
});
workDecrease.addEventListener('click',()=>{
  handleIncrease(workTime,-1);
});

restIncrease.addEventListener('click',()=>{
  handleIncrease(restTime,1);
});
restDecrease.addEventListener('click',()=>{
  handleIncrease(restTime,-1);
});

safe_time=()=>{
  topic_id=document.getElementById('topic_id').getAttribute("value")
  console.log(topic_id);
  // topic_id.split(',')
  
  // window.location = '/light-of-day/safe/'+ topic_id.split(',')[0]+'/' + workTime.innerText+'/' + restTime.innerText;
  // window.location = window.location.href+'/' +restTime.innerText +'/' + workTime.innerText;
  if (window.location.href.includes('topic')){
    // window.location = '/light-of-day/topic/'+ topic_id.split(',')[0]+'/' +restTime.innerText +'/' + workTime.innerText;
    window.location = window.location.href.split('/').slice(0,6).join('/')+'/' +restTime.innerText +'/' + workTime.innerText;
  }
  else{
    // console.log(window.location.href.split('/').slice(1,6).join('/'));
    window.location = window.location.href.split('/').slice(0,6).join('/')+'/' +restTime.innerText +'/' + workTime.innerText;
  }
  // window.location = '/light-of-day/topic/'+topic_id;
}
// console.log(window.location.href)

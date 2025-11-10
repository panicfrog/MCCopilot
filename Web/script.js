let counter = 0;

function updateCounter() {
    document.getElementById('counter').textContent = counter;
}

function incrementCounter() {
    counter++;
    updateCounter();
    console.log('Counter incremented:', counter);
}

function decrementCounter() {
    counter--;
    updateCounter();
    console.log('Counter decremented:', counter);
}

function resetCounter() {
    counter = 0;
    updateCounter();
    console.log('Counter reset');
}

// 页面加载完成
document.addEventListener('DOMContentLoaded', function() {
    console.log('Web page loaded successfully from local:// protocol');
    console.log('Current location:', window.location.href);
});


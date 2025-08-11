function playVideo(videoSrc, videoTitle) {
  const videoElement = document.getElementById("main-video");
  const titleElement = document.getElementById("video-title");
  if (!videoElement || !titleElement) return;
  videoElement.src = videoSrc;
  titleElement.textContent = videoTitle;
  videoElement.play();
}


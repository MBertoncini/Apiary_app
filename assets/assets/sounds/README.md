# Sound Assets for Voice Recognition

This directory contains sound files for the voice recognition feedback in the app.

You should download or create the following sound files:

1. `start_listening.mp3` - A short beep sound when voice recording starts
2. `stop_listening.mp3` - A different beep sound when voice recording stops
3. `success.mp3` - A positive feedback sound for successful recognition
4. `error.mp3` - An error feedback sound for failed recognition

These files should be:
- Short (less than 1 second each)
- In MP3 format
- Appropriately sized (less than 50KB each)

## Sound Sources

You can find free sound effects from the following sites:
- https://freesound.org/
- https://mixkit.co/free-sound-effects/
- https://www.zapsplat.com/

## Implementation

These sounds are used by the `AudioService` class in the application to provide auditory feedback during voice recognition operations.V
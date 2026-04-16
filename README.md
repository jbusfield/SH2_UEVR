# SH2_UEVR
A VR first person mod for UEVR when playing Silent Hill 2

### Credits
Thanks to Praydog, for both UEVR that makes these mods possible and his original melee combat code which is used by this mod nearly unchanged

### Features
- Full 1st person 6DOF Motion controls
- Visible body
- Optional Forearms Only or Full Two Bone IK arms
- Articulated and animated hands
- Option to attach the UI to head movement
- Support for physical gunstocks (not virtual gunstocks)
- Fully retains Praydog's melee combat

### Instructions
The mod has many configurable options. Open the UEVR overlay and click the Silent Hill 2 Config tab to access all of the options

<img width="350" height="474" alt="sh2_1" src="https://github.com/user-attachments/assets/fb2cb7e9-6d1d-4f43-b5aa-b6adbd2c03cb" />

#### Forward Movement Direction
Selecting Follows Head allows for full roomscale movement. Selecting Game will use only stick movements to control player movements but roomscale play will then not be supported.
#### Hands Type
None - no visible hands
Forearms - only forearms and hands are visible (no IK)
IK Arms - 2 Bone IK arms are used
#### Light Location
You have the option to attach the flashlight to your head, off hand or weapon hand. When the flashlight is in your offhand the flashlight mesh will be shown in your hand.
When Interaction Controls are set to "Mixed" you also have the option of using gestures to place the flashlight location. An offhand grab on top of your head above the HMD will move the flashlight from your head to your offhand and vice versa. Same with the weapon hand although the weapon hand wont hold the flashlight mesh, it will only control the light direction
#### Hide Head
It is recommended to keep Hide Head checked with the only downside that player shadows wont show the head. When Hide Head is unchecked there can be occasional minor visual glitches.
#### Offhand Can Grip Weapon
With this option checked, when using the shotgun and rifle and moving your offhand near the weapon offhand grip location, the offhand will animate grabbing the weapon. This feature is best with physical gunstocks but can be interesting even without.
#### Enable Raytracing
With this option unchecked, raytracing is disabled, providing a significant performance boost. However, there can be annoying visual glitch when running without raytracing. The Fix Visual Glitches option fixes these issue and runs every 10 seconds by default.
#### Interaction
You can use Vanilla interaction and use the native game controls, or use Mixed interaction which allows for enhanced VR mechanics

### Coming Soon
Left handed support


function BitsPlusIdentityClutTest(whichScreen, dpixx)
% Test proper function of the T-Lock mechanism, proper loading of identity
% gamma tables into the GPU, and for bad interference of dithering hardware
% with the DVI stream. This test is meant for Mono++ mode of Bits+, it
% won't work properly in any other mode!!
%
% Disclaimer: This test only exists because of the huge number of serious &
% embarassing bugs in the graphics drivers and operating systems from
% Microsoft, Apple, AMD and NVidia. All problems diagnosed here are neither
% defects in the Bits+ device or similar devices, nor Psychtoolbox bugs. As
% such, sadly they are mostly out of our control and there is only a
% limited number of ways we can try to help you to workaround the problems
% caused by miserable workmanship and insufficient quality control at those big
% companies.
%
% Usage:
%
% BitsPlusIdentityClutTest([whichScreen=max][usedpixx=0]);
%
% How to test:
%
% 1. Make sure your Bits+ box is switched to Mono++ mode by uploading the
%    proper firmware.
%
% 2. Run the BitsPlusImagingPipelineTest script to validate that your
%    graphics card can create properly formatted images in the framebuffer
%    for Bits+.
%
% 3. Run this script, optionally passing a screenid. It will test the
%    secondary display on a multi-display setup by default, or the external
%    display on a laptop.
%
% If everything works, what you see onscreen should match the description
% in the blue text that is displayed.
%
% If a wrong gamma lut is uploaded into your GPU due to operating system
% and graphics driver bugs, you can try to toggle through different
% alternative lut's by repeatedly pressing the SPACE key and seeing if the
% display changes for the better. Should you find a setting that works, you
% can press the 's' key to save this configuration and Psychtoolbox will
% use this setting in all future sessions of your experiment scripts.
%
% You can exit the test by pressing the ESCape key, regardless if it was
% successfull or not.
%
% What could also happen is that you get a partial success: The display
% behaves roughly as described in the text, but you see the T-Lock color
% code line at the top of your display erratically appearing and
% disappearing - flickering. You also don't see a smooth animation of the
% drifting horizontal red gradient or a regular cycling of the "COLORFUL"
% words, but some jerky, irregular, jumpy animation, which may only update
% a few times per second, or even only once every couple seconds or at very
% irregular intervals. You may also see the display overlayed with random
% colorful speckles, or you may not see the gray background image and gray
% rotating gradient patch at all. In that case, the lut uploaded in your
% GPU may be correct, but due to some serious graphics driver or operating
% system bug, the GPU is applying spatial or temporal dithering to the
% video stream which will confuse the Bits+ and cause random artifacts and
% failure of the T-Lock mechanism.
%
% You should also double-check the cabling and connections to rule out
% connection problems and other defects.
%
% In that case, contact CRS support or check the Psychtoolbox Wiki for a
% workaround. Currently we have a workaround for MacOS/X systems, but not
% for MS-Windows systems.
%

% History:
% 09/20/09  mk  Written.

% Select screen for test/display:
if nargin < 1 || isempty(whichScreen)
    whichScreen = max(Screen('Screens'));
end

if nargin < 2
    dpixx = 0;
end

% Disable text anti-aliasing for this test:
oldAntialias = Screen('Preference', 'TextAntiAliasing', 0);

try
    % Setup imaging pipeline:
    PsychImaging('PrepareConfiguration');

    % Require a 32 bpc float framebuffer: This would be the default anyway, but
    % just here to be explicit about it:
    PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');

    % Make sure we run with our default color correction mode for this test:
    % 'ClampOnly' is the default, but we set it here explicitely, so no state
    % from previously running scripts can bleed through:
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly');

    if dpixx
        % Use Mono++ mode with overlay:
        PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
    else
        % Use Mono++ mode with overlay:
        PsychImaging('AddTask', 'General', 'EnableBits++Mono++OutputWithOverlay');
    end
    
    % Open the window, assign a gray background color with a 50% intensity gray:
    [win, screenRect] = PsychImaging('OpenWindow', whichScreen, 0.5);

    % Get handle to overlay:
    overlaywin = PsychImaging('GetOverlayWindow', win);

    HideCursor;

    % At this point we should have a fullscreen onscreen window, with automatic
    % output for Bits+ Mono++ mode, with a overlay whose color is controlled
    % via T-Lock based CLUT's. The whole thing for 32 bit floating point
    % luminance precision, ie., about 23 bits of linear precision -- more than
    % sufficient for the 14 bit DAC output of the Bits+.
    %
    % The color overlay should have a white color ramp loaded.
    % The GPU should have an identity gamma table loaded, so our test images
    % will display without artifacts.
    %
    % Let's create a test stim. This one should display nicely if everything is
    % fined, but should screw up in different ways if something is wrong with
    % the GPU's gamma tables, dithering hardware or other components that
    % affect the creation of the final DVI-Digital drive signals from the
    % framebuffer content. We know that the framebuffer content is fine,
    % because the setup has already passed the BitsPlusImagingPipelineTest
    % script (otherwise the user would be unable to run this testscript at
    % all).

    % Generate a synthetic grating that covers the whole
    % intensity range from 0 to 16384, mapped to the 0.0 - 1.0 range:
    theImage=zeros(256,256,1);
    theImage(:,:)=reshape(double(linspace(0, 2^16 - 1, 2^16)), 256, 256)' / (2^16 - 1);

    % Build HDR texture:
    hdrtexIndex= Screen('MakeTexture', win, theImage, [], [], 2);

    % Create static image in overlay window:
    Screen('TextSize', overlaywin, 18);
    mytext = ['This is what you should see if everything works correctly:\n\n' ...
        'This text should be shown in blue.\n' ...
        'The "COLORFUL" couple of lines below should cycle through different\n' ...
        'rainbow colors at a rate of multiple frames per second.\n\n' ...
        'You should see some smoothly "drifting" red gradient-like pattern.\n' ...
        'And some rotating gray level gradient test patch. All in front of a gray background.\n\n' ...
        'What you should not see is random speckles of color somewhere on the screen, or a\n' ...
        'jerky animation with only occassional updates.\n\n' ...
        'If what you see is not what you should see, try to cycle through different\n' ...
        'settings by repeatedly pressing the SPACE key on the keyboard.\n' ...
        'If some setting works for you, press "s" key to save the configuration.\n' ...
        'Press the ESCape key to exit from this test.\n\n' ...
        'If everything else fails, read the manual ;-) - Or the help to this test.\n\n'];

    [nx, ny] = DrawFormattedText(overlaywin, mytext, 'center', 30, 255);

    [nx, ny] = DrawFormattedText(overlaywin, 'COLORFUL0\n', 'center', ny, 250);
    [nx, ny] = DrawFormattedText(overlaywin, 'COLORFUL1\n', 'center', ny, 251);
    [nx, ny] = DrawFormattedText(overlaywin, 'COLORFUL2\n', 'center', ny, 252);
    [nx, ny] = DrawFormattedText(overlaywin, 'COLORFUL3\n', 'center', ny, 253);
    [nx, ny] = DrawFormattedText(overlaywin, 'COLORFUL4\n', 'center', ny, 254);

    xpos = round((RectWidth(screenRect) - 150*4) / 2);
    for x=100:249
        Screen('DrawLine', overlaywin, x, xpos, ny + 20, xpos+3, ny+10, 5);
        xpos = xpos + 4;
    end

    % Create LUT for Mono++ overlay:
    ovllut = ones(256, 3);

    % This fills the first 100 slots with random colors. Given that our overlay
    % window is cleared to colorindex zero by default - which means:
    % Transparent for the "underlying" Mono++ luminance image, and given that
    % we don't use color indices 1-100 in our overlay anywhere, this random
    % color assignment should have no perceptible effect whatsoever. If the
    % gamma LUT's of the GPU however contains wrong values or some offset is
    % introduced somwhere on the way from the framebuffer to the DVI-Port, then
    % this will cause some or all of the pixel components in the blue channel
    % of the framebuffer image to be output as non-zero values --> Bits+
    % interprets these non-zero components in the blue channel as overlay
    % pixels and assigns these random colors to the displayed image --> we will
    % see lots of random colorful flickering junk on the display.
    ovllut(1:100,:) = rand(100,3);

    % Build red gradient in slots 101 to 250:
    ovllut(101:250, 1) = linspace(0,1,150)';
    ovllut(101:250, 2:3) = 0;

    % Build random colors in slots 251:255:
    ovllut(251:255,:) = rand(5,3);

    % Last slot is blue:
    ovllut(256, :) = [0 , 0, 1];
    
    angle = 0;
    lutidx = -1;

    KbName('UnifyKeyNames');
    escape = KbName('ESCAPE');
    space = KbName('space');
    key_s = KbName('s');

    KbReleaseWait;

    while 1
        % Load new T-Lock CLUT at next flip:
        Screen('LoadNormalizedGammatable', win, ovllut, 2);

        % Draw rotated luminance patch:
        angle = angle + 1;
        Screen('DrawTexture', win, hdrtexIndex, [], [], angle/10);

        % Update display:
        Screen('Flip', win);

        % Update ovllut for color animations:

        % Red color gradient shifts at each refresh:
        ovllut(101:250, :) = circshift(ovllut(101:250, :), 1);

        % Colored text cycles every 30 frames:
        if mod(angle, 30) == 0
            ovllut(251:255, :) = circshift(ovllut(251:255, :), 1);
        end

        % Color in low slots gets re-randomized:
        ovllut(1:100,:) = rand(100,3);

        [isdown, secs, keyCode] = KbCheck;
        if isdown
            if keyCode(escape)
                break;
            end

            if keyCode(space)
                % Match 'lutidx' with available indices in LoadIdentityClut!!
                % Currently indices 0 to 3 are available, ie., 4 indices total:
                lutidx = mod(lutidx + 1, 4);
                fprintf('Switching GPU identity CLUT to type %i.\n', lutidx);

                % Upload new corresponding gamma table immediately to GPU:
                LoadIdentityClut(win, 0, lutidx);
                Beeper;
            end

            if keyCode(key_s)
                if lutidx ~= -1
                    fprintf('Storing override GPU identity CLUT type %i in configuration file.\n', lutidx);
                    SaveIdentityClut(win, lutidx);
                    Beeper;
                end
            end
            KbReleaseWait;
        end
    end

    % Load identity CLUT into Bits++ to restore proper display:
    BitsPlusPlus('LoadIdentityClut', win);

    % This flip is needed for the 'LoadIdentityClut' to take effect:
    Screen('Flip', win);
    
    % Done. Close everything down:
    ShowCursor;
    Screen('CloseAll');
    RestoreCluts;
    Screen('Preference', 'TextAntiAliasing', oldAntialias);

    fprintf('Finished. Bye.\n\n');

catch
    sca;
    Screen('Preference', 'TextAntiAliasing', oldAntialias);
    psychrethrow(psychlasterror);
end

return;

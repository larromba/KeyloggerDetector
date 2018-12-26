//
//  main.m
//  KeyloggerDetector
//
// Locates if there is any keyloggers located on the system and the location
//
//  Created by User on 12/26/18.
//  Copyright © 2018 Stuart Ashenbrenner. All rights reserved.
//
#import <notify.h>
#import <libproc.h>
#import <Foundation/Foundation.h>




// path from the pid
NSString* pathFromPid(pid_t pid)
{
    // buffer the process path
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE] = {0};
    
    proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
    
    return [NSString stringWithUTF8String:pathBuffer];
}

// current taps
NSMutableDictionary* listTaps()
{
    // keyboard taps
    NSMutableDictionary* keyboardTaps = nil;
    
    // event taps
    uint32_t eventTapCount = 0;
    
    // taps
    CGEventTapInformation *taps = NULL;
    
    // current taps
    CGEventTapInformation tap = {0};
    
    // key tap
    CGEventMask keyboardTap = CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventKeyDown);
    
    // path
    NSString* tappingProcess = nil;
    
    // allocate
    keyboardTaps = [NSMutableDictionary dictionary];
    
    // get all taps
    if (kCGErrorSuccess != CGGetEventTapList(0, NULL, &eventTapCount))
    {
        // bail
        goto bail;
    }
    
    // debug message
    NSLog(@"found %d taps", eventTapCount);
    
    // allocate
    taps = malloc(sizeof(CGEventTapInformation) * eventTapCount);
    if (NULL == taps)
    {
        // bail
        goto bail;
    }
    
    // get all taps
    if (kCGErrorSuccess != CGGetEventTapList(eventTapCount, taps, &eventTapCount))
    {
        // bail
        goto bail;
    }
    
    // interate through and process all taps
    for (int i = 0; i < eventTapCount; i++)
    {
        tap = taps[i];
        
        if (true != tap.enabled)
        {
            // skip
            continue;
        }
        
        // ignore non-keypresses
        if ( (keyboardTap & tap.eventsOfInterest) != keyboardTap)
        {
            // skip
            continue;
        }
        
        // get path to process
        tappingProcess = pathFromPid(tap.tappingProcess);
        
        
        
        // add
        keyboardTaps[@(tap.tappingProcess)] = @{@"path": tappingProcess, @"target": @(tap.processBeingTapped)};
    }
    
bail:
    return keyboardTaps;
    
}

// Main function
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        // existing keyboard taps
        __block NSMutableDictionary* taps = nil;
        
        // (re)enumerated taps
        __block NSMutableDictionary* currentTaps = nil;
        
        // new taps
        __block NSMutableSet* newTaps = nil;
        
        
        // init taps
        taps = listTaps();
        
        // debug message/generate list of taps
        NSLog(@"detected %lu existing keyboard taps", (unsigned long)taps.count);
        for (NSNumber* tap in taps)
        {
            NSLog(@"tap (process: %@): %@", tap, taps[tap]);
        }
        
        // register for live, new keyboard taps
        int notifyToken = 0; // unregister with notify_cancel()
        notify_register_dispatch(kCGNotifyEventTapAdded, &notifyToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token) {
            
            // (re)enumerate taps
            currentTaps = listTaps();
            
            // new taps
            newTaps = [NSMutableSet setWithArray:currentTaps.allKeys];
            
            [newTaps minusSet:[NSSet setWithArray:taps.allKeys]];
            
            // check for new taps
            if (0 != newTaps.count)
            {
                NSLog(@"detecte %lu new keyboard taps", (unsigned long)newTaps.count);
                
                for (NSNumber* tap in newTaps)
                {
                    NSLog(@"tap (process: %@): %@", tap, currentTaps[tap]);
                }
            }
            
            // update
            taps = currentTaps;
            
        });
        
        // run
        [[NSRunLoop currentRunLoop] run];

    }
    
    return 0;
}

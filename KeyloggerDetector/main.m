//
//  main.m
//  KeyloggerDetector
//
//  Created by User on 12/26/18.
//  Copyright © 2018 Stuart Ashenbrenner. All rights reserved.
//
#import <notify.h>
#import <libproc.h>

#import <Foundation/Foundation.h>

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
    if(kCGErrorSuccess != CGGetEventTapList(0, NULL, &eventTapCount))
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
        
        if(true != tap.enabled)
        {
            // skip
            continue;
        }
        
        // ignore non-keypresses
        if( (keyboardTap & tap.eventsOfInterest) != keyboardTap)
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
        
        // debug message
        NSLog(@"detected %lu existing keyboard taps", (unsigned long)taps.count);
        for(NSNumber* tap in taps)
        {
            NSLog(@"tap (process: %@): %@", tap, taps[tap]);
        }
        
        
    }
    return 0;
}

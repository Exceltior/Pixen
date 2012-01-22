//
//  PXToolSwitcher.m
//  Pixen
//

#import "PXToolSwitcher.h"
#import "PXPencilTool.h"
#import "PXEraserTool.h"
#import "PXEyedropperTool.h"
#import "PXZoomTool.h"
#import "PXFillTool.h"
#import "PXLineTool.h"
#import "PXRectangularSelectionTool.h"
#import "PXMoveTool.h"
#import "PXRectangleTool.h"
#import "PXEllipseTool.h"
#import "PXMagicWandTool.h"
#import "PXLassoTool.h"
#import "PXNotifications.h"

#import "PXColorPicker.h"

NSMutableArray * toolNames;

  // a protocol interface + bundle loader would be better

@implementation PXToolSwitcher


+(NSArray *) toolClasses
{
	return [NSArray arrayWithObjects:[PXPencilTool class], 
          [PXEraserTool class], [PXEyedropperTool class],
          [PXZoomTool class], [PXFillTool class], 
          [PXLineTool class], [PXRectangularSelectionTool class],
          [PXMoveTool class], [PXRectangleTool class],
          [PXEllipseTool class], [PXMagicWandTool class],
          [PXLassoTool class], nil];
}

+(id) toolNames
{
  return [[self toolClasses] valueForKey:@"description"];
}

- (void)lock
{
  _locked = YES;
}

- (void)unlock
{
  _locked = NO;
}

- (void)awakeFromNib
{
	[toolsMatrix setDoubleAction:@selector(toolDoubleClicked:)];
}

- (id)init
{
	if ( ! ( self = [super init] ))
		return nil;
	
	tools = [[NSMutableArray alloc] initWithCapacity:[[[self class] toolClasses] count]];
	
	for (Class current in [[self class] toolClasses])
	{
		[tools addObject:[[[current alloc] init] autorelease]];
	}
	
	[tools makeObjectsPerformSelector:@selector(setSwitcher:) withObject:self];
	[self setColor:[[NSColor blackColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]];
	[self useToolTagged:PXPencilToolTag];
	
	_locked = NO;
	[self checkUserDefaults];
	
	return self;
}

//FIXME: private ?
//Not sure what this was warning about -- though we do in general mix private and 'public' methods a bit much, we should make use of categories.
- (void)checkUserDefaults
{
	//should find a way to factor this into the tools' classes.
	//Leaks ??
	NSArray *arrayObjects = [NSArray arrayWithObjects:@"p", @"e", @"d", @"z", 
							 @"f", @"l", @"s", @"m", @"r", @"o", @"w", 
							 @"a", nil];
	
	NSArray *arrayKeys = [NSArray arrayWithObjects:
						  [NSNumber numberWithInt:PXPencilToolTag],
						  [NSNumber numberWithInt:PXEraserToolTag],
						  [NSNumber numberWithInt:PXEyedropperToolTag],
						  [NSNumber numberWithInt:PXZoomToolTag],
						  [NSNumber numberWithInt:PXFillToolTag],
						  [NSNumber numberWithInt:PXLineToolTag],
						  [NSNumber numberWithInt:PXRectangularSelectionToolTag],
						  [NSNumber numberWithInt:PXMoveToolTag],
						  [NSNumber numberWithInt:PXRectangleToolTag],
						  [NSNumber numberWithInt:PXEllipseToolTag],
						  [NSNumber numberWithInt:PXMagicWandToolTag],
						  [NSNumber numberWithInt:PXLassoToolTag],
						  nil];
	
	NSDictionary *defaultShortcuts = [NSDictionary dictionaryWithObjects:arrayObjects
																 forKeys:arrayKeys];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *tmp;
	
	for (NSString *current in [defaultShortcuts keyEnumerator])
	{
		tmp = [[[self class] toolNames] objectAtIndex:[current intValue]];
		
		if ( ! [userDefaults objectForKey:tmp])
			[userDefaults setObject:[defaultShortcuts objectForKey:current] forKey:tmp];
	}
}

- (void)dealloc
{
  [tools release];
  [super dealloc];
}

- (id) selectedTool
{
  return _tool;
}

-(id) toolWithTag:(PXToolTag)tag
{
  return [tools objectAtIndex:tag];
}

- (PXToolTag)tagForTool:(id) aTool
{
  return (PXToolTag)[tools indexOfObject:aTool];
}

- (void)setIcon:(NSImage *)anImage forTool:(id)aTool
{
  [[toolsMatrix cellWithTag:[self tagForTool:aTool]] setImage:anImage];
}

- (void)useTool:(id) aTool
{
  [self useToolTagged:[self tagForTool:aTool]];
}

- (void)useToolTagged:(PXToolTag)tag
{
	if ( _locked ) 
		return;
  
	_lastTool = _tool;
	_tool = [self toolWithTag:tag];
	[_tool clearBezier];
	[toolsMatrix selectCellWithTag:tag];
	[[NSNotificationCenter defaultCenter] postNotificationName:PXToolDidChangeNotificationName 
                                                      object:self 
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_tool, PXNewToolKey,nil]];
}

- (void)requestToolChangeNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PXToolDidChangeNotificationName 
                                                      object:self 
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_tool, PXNewToolKey,nil]];
}

- (NSColor *) color
{
  return _color;
}

- (void)activateColorWell
{
	[colorWell activate:YES];
}

- (void)clearBeziers
{
	[tools makeObjectsPerformSelector:@selector(clearBezier)];
}

- (void)setColor:(NSColor *)color
{
	//FIXME: coupled
	[_color release];
	_color = [color retain];
	
	for (PXTool *currentTool in tools) {
		[currentTool setColor:PXColorFromNSColor(_color)];
	}
	
	[colorWell setColor:_color];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PXToolColorDidChangeNotificationName
														object:self];
}

- (IBAction)colorChanged:(id)sender
{
	[self setColor:[[colorWell color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]];
}

- (IBAction)toolClicked:(id)sender
{
	
  [self useToolTagged:(PXToolTag)[[toolsMatrix selectedCell] tag]];
}

- (IBAction)toolDoubleClicked:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PXToolDoubleClickedNotificationName object:self];
}

- (void)keyDown:(NSEvent *)event fromCanvasController:(PXCanvasController *)cc
{
	NSString *chars = [[event charactersIgnoringModifiers] lowercaseString];
	
	for (NSString *current in [PXToolSwitcher toolNames])
	{
		if ([chars characterAtIndex:0] == [[[NSUserDefaults standardUserDefaults] objectForKey:current] characterAtIndex:0])
		{
			[self useToolTagged:(PXToolTag)[[PXToolSwitcher toolNames] indexOfObject:current]];
			break;
		}
	}
	
	[[self toolWithTag:PXMoveToolTag] keyDown:event fromCanvasController:cc];
}

- (void)optionKeyDown
{
  if( ! [_tool optionKeyDown] ) { 
		[self useToolTagged:PXEyedropperToolTag];
  }
}

- (void)optionKeyUp
{
  if( ! [_tool optionKeyUp] ) { 
		[self useTool:_lastTool];
  }
}
- (void)shiftKeyDown
{
  [_tool shiftKeyDown];
}

- (void)shiftKeyUp
{
  [_tool shiftKeyUp];
}

- (void)commandKeyDown
{
	[_tool commandKeyDown];
}

- (void)commandKeyUp
{
	[_tool commandKeyUp];
}

@end

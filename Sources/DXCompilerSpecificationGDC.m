
// D for Xcode: Compiler Specification
// Copyright (C) 2007  Michel Fortin
//
// D for Xcode is free software; you can redistribute it and/or modify it 
// under the terms of the GNU General Public License as published by the Free 
// Software Foundation; either version 2 of the License, or (at your option) 
// any later version.
//
// D for Xcode is distributed in the hope that it will be useful, but WITHOUT 
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
// more details.
//
// You should have received a copy of the GNU General Public License
// along with D for Xcode; if not, write to the Free Software Foundation, 
// Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.

#import "DXCompilerSpecificationGDC.h"
#import "DXParserTools.h"

#import "XCPBuildSystem.h"
#import "XCPDependencyGraph.h"
#import "XCPSupport.h"


@implementation DXCompilerSpecificationGDC

+ (void)initialize {
	PBXFileType *type = (PBXFileType*)[PBXFileType specificationForIdentifier:@"sourcecode.d"];
	XCCompilerSpecification *spec = (XCCompilerSpecification*)[XCCompilerSpecification specificationForIdentifier:@"com.michelf.dxcode.gdc"];
	[PBXTargetBuildContext activateImportedFileType:type withCompiler:spec];
	
	DXParserInit();
}

- (NSArray *)importedFilesForPath:(NSString *)path ensureFilesExist:(BOOL)ensure inTargetBuildContext:(PBXTargetBuildContext *)context
{
//	NSString* outputDir = [context expandedValueForString:@"$(OBJFILES_DIR_$(variant))/$(arch)"];
	XCDependencyNode* inputNode = [context dependencyNodeForName:path createIfNeeded:YES];
	
	NSSet *filenames = DXSourceDependenciesForPath([NSString stringWithContentsOfFile:path]);
	NSMutableArray *imported = [NSMutableArray arrayWithCapacity:[filenames count]];

	NSEnumerator *e = [filenames objectEnumerator];
	NSString *filename;
	while (filename = [e nextObject]) {
		NSString *filepath = [context absolutePathForPath:filename];
		XCDependencyNode *node = [context dependencyNodeForName:filepath createIfNeeded:YES];
		[node setDontCareIfExists:YES];
		[inputNode addIncludedNode:node];
		[imported addObject:filename];

//		if ([context expandedBooleanValueForString:@"$(GDC_GENERATE_INTERFACE_FILES)"] &&
//			[filepath hasSuffix:@".d"])
//		{
//			NSString *objRoot = [context expandedValueForString:@"$(OBJROOT)"];
//			NSString *interfaceDir = [objRoot stringByAppendingPathComponent:@"dinterface"];
//			NSString *interfaceFile = [interfaceDir stringByAppendingPathComponent:[filepath stringByAppendingPathExtension:@"di"]];
//			
//			node = [context dependencyNodeForName:interfaceFile createIfNeeded:YES];
//			[node setDontCareIfExists:YES];
//			[inputNode addIncludedNode:node];
//			[imported addObject:filename];
//		}
	}
	
	return imported;
}


- (NSArray *)computeDependenciesForInputFile:(NSString *)input ofType:(PBXFileType*)type variant:(NSString *)variant architecture:(NSString *)arch outputDirectory:(NSString *)outputDir inTargetBuildContext:(PBXTargetBuildContext *)context
{
	// compute input file path
	input = [context expandedValueForString:input];
	
	// compute output file path
	NSString *basePath = [input stringByDeletingPathExtension];
	NSString *relativePath = [context naturalPathForPath:basePath];
	NSString *baseName = [relativePath stringByReplacingCharacter:'/' withCharacter:'.'];
	NSString *output = [baseName stringByAppendingPathExtension:@"o"];
	output = [outputDir stringByAppendingPathComponent:output];
	output = [context expandedValueForString:output];
	
	// create dependency nodes 
	XCDependencyNode *outputNode = [context dependencyNodeForName:output createIfNeeded:YES];
	XCDependencyNode *inputNode = [context dependencyNodeForName:input createIfNeeded:YES];
	
	// create compiler command
	XCDependencyCommand *dep = [context
		createCommandWithRuleInfo:[NSArray arrayWithObjects:@"CompileD", [context naturalPathForPath:input],nil]
		commandPath:[context expandedValueForString:[self path]]
		arguments:nil
		forNode:outputNode];
	[dep setToolSpecification:self];
	[dep addArgumentsFromArray:[self commandLineForAutogeneratedOptionsInTargetBuildContext:context]];
	[dep addArgumentsFromArray:[[context expandedValueForString:@"$(build_file_compiler_flags)"] arrayByParsingAsStringList]];
	
	// Need to handle this flag programatically to avoid classing with zerolink.
	if([context expandedBooleanValueForString:@"$(GDC_DYNAMIC_NO_PIC)"]) {
		if(![context expandedBooleanValueForString:@"$(ZERO_LINK)"]) {
			[dep addArgument:@"-mdynamic-no-pic"];
		}
	}
	
	[dep addArgument:@"-c"];
	[dep addArgument:@"-o"];
	[dep addArgument:output];
	[dep addArgument:input];
	
	// Create dependency rules (must be done after dependency command creation)
	[outputNode addDependedNode:inputNode];
	
	// Tell Xcode to use the GDC linker.
	[context setStringValue:@"com.michelf.dxcode.gdc.linker" forDynamicSetting:@"compiler_mandated_linker"];
	
//	if ([context expandedBooleanValueForString:@"$(GDC_GENERATE_INTERFACE_FILES)"]) {
//		NSString *objRoot = [context expandedValueForString:@"$(OBJROOT)"];
//		NSString *interfaceDir = [objRoot stringByAppendingPathComponent:@"dinterface"];
//		[dep addArgument:@"-I"];
//		[dep addArgument:interfaceDir];
//		
//		NSString *interfaceFile = [interfaceDir stringByAppendingPathComponent:[relativePath stringByAppendingPathExtension:@"di"]];
//		[dep addArgument:[NSString stringWithFormat:@"-fintfc-file=%@", interfaceFile]];
//	}
	
	// update source <-> output links
	[context setCompiledFilePath:output forSourceFilePath:input];
		
	// set output objects
	return [NSArray arrayWithObject:outputNode];
}

@end

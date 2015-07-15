//
//  ProjectsViewController.m
//  MorphUs
//
//  Created by Dan Shepherd on 11/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#import "ProjectsViewController.h"
#import "MorphViewController.h"
#import "ProjectsTableViewCell.h"
#import "MorphSettingsTableViewController.h"

@interface ProjectsViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (assign, atomic) NSInteger selectedRow;

@end

@implementation ProjectsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // single selection only during editing
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    // Initialize Fetch Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Project"];
    
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Configure Fetched Results Controller
    [self.fetchedResultsController setDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }

}

#pragma mark - General project cell management

- (void)configureCell:(ProjectsTableViewCell*)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Fetch Record
    NSManagedObject *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Update Cell
    [cell.name setText:[record valueForKey:@"name"]];
    NSDate* createdAt = [record valueForKey:@"createdAt"];
    NSString* createdAtString = [NSDateFormatter localizedStringFromDate:createdAt
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    [cell.created setText:[NSString stringWithFormat:@"Created %@", createdAtString]];
    NSData* image = [record valueForKey:@"thumbImage"];
    if(image == NULL)
        [cell.thumbImageView setImage:[UIImage imageNamed:@"ProjectPlaceholder"]];
    else
    {
        NSData* data = [record valueForKey:@"thumbImage"];
        UIImage* thumb = [UIImage imageWithData:data];
        [cell.thumbImageView setImage:thumb];
    }
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
}

- (NSManagedObject*)addNewProject
{
    NSString* name = [NSString stringWithFormat:@"Morph"];
    // Create Entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
    
    // Initialize Record
    NSManagedObject* record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    
    // Populate Record
    [record setValue:name forKey:@"name"];
    [record setValue:[NSDate date] forKey:@"createdAt"];
    
    // Save Record
    NSError *error = nil;
    
    if ([self.managedObjectContext save:&error]) {
        return record;
    } else {
        if (error) {
            NSLog(@"Unable to save record.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        
        // Show Alert View
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Morph project could not be saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return nil;
    }
}

- (NSManagedObject*)selectProjectAt:(NSInteger)row
{
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"Project"];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    NSError* error;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if(row >= results.count)
        return nil;
    else
        return [results objectAtIndex:row];
}

#pragma mark - Fetch results delegates

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(ProjectsTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

#pragma mark - Table View delegates

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (record) {
            [self.fetchedResultsController.managedObjectContext deleteObject:record];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProjectsTableViewCell* cell = (ProjectsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"ProjectCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedRow = indexPath.row;
    [self performSegueWithIdentifier:@"existingMorph" sender:self];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRow = indexPath.row;
    [self performSegueWithIdentifier:@"morphSettings" sender:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor blackColor];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.tableView setEditing:NO];
    if([[segue identifier] isEqualToString:@"newMorph"])
    {
        MorphViewController* vc = (MorphViewController*)[segue destinationViewController];
        [vc setManagedObjectContext:self.managedObjectContext];
        [vc setManagedObject:[self addNewProject]];
    }
    else if([[segue identifier] isEqualToString:@"existingMorph"])
    {
        MorphViewController* vc = (MorphViewController*)[segue destinationViewController];
        [vc setManagedObjectContext:self.managedObjectContext];
        [vc setManagedObject:[self selectProjectAt:self.selectedRow]];
    }
    else if([[segue identifier] isEqualToString:@"morphSettings"])
    {
        MorphSettingsTableViewController* vc = (MorphSettingsTableViewController*)[segue destinationViewController];
        [vc setManagedObjectContext:self.managedObjectContext];
        [vc setManagedObject:[self selectProjectAt:self.selectedRow]];
    }
}
 

@end

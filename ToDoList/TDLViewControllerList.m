//
//  TDLViewControllerList.m
//  ToDoList
//
//  Created by Woudini on 12/10/14.
//  Copyright (c) 2014 Hi Range. All rights reserved.
//
// This is the working version. Cascade rule reversed and corrected.

#import "TDLViewControllerList.h"
#import "TDLViewController.h"
#import <CoreData/Coredata.h>
#import "ListCell.h"
#import "List.h"

@interface TDLViewControllerList ()<NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;


@end

@implementation TDLViewControllerList

#pragma mark Add List

// Button located on top right of screen to enable user to add a list
- (IBAction)addListButton:(UIBarButtonItem *)sender
{
    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"New List"
                                                          message:@""
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"OK", nil];
    myAlertView.alertViewStyle=UIAlertViewStylePlainTextInput;
    [myAlertView show];
}

// Adding a list
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *listName = [alertView textFieldAtIndex:0];
    if ([listName.text length])
    {
        NSString *listNameString = listName.text;
        NSLog(@"The name is %@",listNameString);
        
        // Create Entity
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"List" inManagedObjectContext:self.managedObjectContext];
        
        // Initialize Record
        NSManagedObject *record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        
        // Populate Record
        [record setValue:listNameString forKey:@"listName"];
            NSLog(@"No. of sections:%lu",(unsigned long)[[self.fetchedResultsController sections] count]);
        
        // Save Record
        NSError *error = nil;
        
        if ([self.managedObjectContext save:&error])
        {
            // Dismiss View Controller
            [self dismissViewControllerAnimated:YES completion:nil];
            
        } else
        {
            if (error)
            {
                NSLog(@"Unable to save record.");
                NSLog(@"%@, %@", error, error.localizedDescription);
            }
            
            // Show Alert View
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your to-do could not be saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
    else
    {
        NSLog(@"No name");
    }
    
}

#pragma mark Prepare For Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TDLViewController"])
    {
        // Obtain Reference to View Controller
        TDLViewController *vc = segue.destinationViewController;
        
        // Configure View Controller
        [vc setManagedObjectContext:self.managedObjectContext];
        
        // Send the View Controller the name of the list that was clicked on
        // Get the List item at indexPathForSelectedRow and set it to change its tasksChanged here
        ListCell *selectedCell = (ListCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        NSLog(@"Selected Row:%ld", (long)[self.tableView indexPathForSelectedRow].row);
        vc.passedListName = selectedCell.nameLabel.text;

    }
        
}

#pragma mark Table View Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}
/*
- (void)moveItemAtIndex:(int)from toIndex:(int)to
{
    if (from == to) {
        return;
    }
    NSMutableArray *listsCopy = [[self.fetchedResultsController sections] mutableCopy];
    List *list = [listsCopy objectAtIndex:from];
    [listsCopy removeObjectAtIndex:from];
    [listsCopy insertObject:list atIndex:to];
    [self saveManagedObjectContext];
}
*/
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            [self configureCell:(ListCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListCell *cell = (ListCell *)[tableView dequeueReusableCellWithIdentifier:@"ListCell" forIndexPath:indexPath];
    
    // Configure Table View Cell
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

// UITableViewDataSource protocol optional method 1
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// UITableViewDataSource protocol optional method 2
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        List *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if (record)
        {
            [self.fetchedResultsController.managedObjectContext deleteObject:record];
        }
    }
    [self saveManagedObjectContext];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects]; //matched 2 tutorials - has to be correct
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count]; //matched 2 tutorials - has to be correct

}

- (void)configureCell:(ListCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Fetch Record
    List *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Update Cell
    cell.nameLabel.text = record.listName;
    
    // Update Cell Subtitle
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    
    // The long way is to create an entity description
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"thatOwns.listName", record.listName];
    
    // Sort descriptors required only for NSFetchedResultsController
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error)
    {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
    } else {
        NSLog(@"%@", result);
    }
    int numberOfTasksForList = (unsigned)[result count];
    int tasksDone = 0;
    
    for (NSManagedObject* task in result)
    {
        if ([[task valueForKey:@"done"] boolValue] == YES)
            tasksDone++;
    }
    
    cell.numberOfItemsLabel.text = [[NSString alloc] initWithFormat:@"%d/%d done", tasksDone,numberOfTasksForList];
    [self saveManagedObjectContext];
    NSLog(@"cell at row %ld configured", (long)indexPath.row);
}

- (void)saveManagedObjectContext
{
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error])
    {
        if (error)
        {
            NSLog(@"Unable to save changes.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure Navigation Item
    self.tableView.rowHeight = 44;
    
    // Initialize Fetch Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"List"];
    

    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"listName" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Configure Fetched Results Controller
    [self.fetchedResultsController setDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    // without fetchedResults Controller: NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error)
    {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

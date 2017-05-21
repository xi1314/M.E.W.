//
//  MEWLocationViewController.m
//  MewApp
//
//  Created by Zheng on 08/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Preferences/PSSpecifier.h>
#import "MEWLocationViewController.h"

static NSString * const kMewMapViewAnnotationIdentifier = @"kMewMapViewAnnotationIdentifier";
static NSString * const kMEWMapViewAnnotationFormat = @"纬度: %f, 经度: %f";

@interface MEWLocationViewController () <MKMapViewDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *pointAnnotation;

@end

@implementation MEWLocationViewController

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSString *)title {
    return [self.specifier propertyForKey:PSTitleKey];
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    mapView.delegate = self;
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.zoomEnabled = YES; mapView.scrollEnabled = YES; mapView.rotateEnabled = YES;
    mapView.showsUserLocation = YES; mapView.showsBuildings = NO; mapView.showsPointsOfInterest = NO;
    START_IGNORE_PARTIAL
    if (XXT_SYSTEM_9) {
        mapView.showsCompass = YES; mapView.showsScale = YES; mapView.showsTraffic = NO;
    }
    END_IGNORE_PARTIAL
    self.mapView = mapView;
    
    CLLocationCoordinate2D defaultCoordinate;
    defaultCoordinate.latitude = 39.92f;
    defaultCoordinate.longitude = 116.46f;
    MKCoordinateSpan defaultSpan = {1.f, 1.f};
    MKCoordinateRegion region = {defaultCoordinate, defaultSpan};
    id latitudeObj = R(kMewEncCoordinateRegionLatitudeKey);
    id longitudeObj = R(kMewEncCoordinateRegionLongitudeKey);
    if (
        latitudeObj && longitudeObj
        ) {
        defaultCoordinate.latitude = [(NSNumber *)latitudeObj floatValue];
        defaultCoordinate.longitude = [(NSNumber *)longitudeObj floatValue];
    }
    [mapView setRegion:region animated:YES];
    
    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.title = @"拖拽以选择位置 📌";
    pointAnnotation.subtitle = [NSString stringWithFormat:NSLocalizedString(kMEWMapViewAnnotationFormat, nil), defaultCoordinate.latitude, defaultCoordinate.longitude];
    pointAnnotation.coordinate = defaultCoordinate;
    [mapView addAnnotation:pointAnnotation];
    [mapView selectAnnotation:pointAnnotation animated:YES];
    self.pointAnnotation = pointAnnotation;
    
    [self.view addSubview:mapView];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == mapView.userLocation) {
        return nil;
    }
    MKPinAnnotationView *customPinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMewMapViewAnnotationIdentifier];
    if (!customPinView) {
        customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMewMapViewAnnotationIdentifier];
        START_IGNORE_PARTIAL
        if (XXT_SYSTEM_9) {
            customPinView.pinTintColor = MAIN_COLOR;
        } else {
            customPinView.pinColor = MKPinAnnotationColorRed;
        }
        END_IGNORE_PARTIAL
        customPinView.animatesDrop = YES;
        customPinView.canShowCallout = YES;
        customPinView.draggable = YES;
    } else {
        customPinView.annotation = annotation;
    }
    return customPinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    MKPointAnnotation *anno = ((MKPointAnnotation *)view.annotation);
    NSString *dragTips = [NSString stringWithFormat:NSLocalizedString(kMEWMapViewAnnotationFormat, nil), anno.coordinate.latitude, anno.coordinate.longitude];
    switch (newState) {
        case MKAnnotationViewDragStateStarting:
            break;
        case MKAnnotationViewDragStateDragging:
            break;
        case MKAnnotationViewDragStateEnding:
            anno.subtitle = dragTips;
            S(kMewEncCoordinateRegionLatitudeKey, @((float) anno.coordinate.latitude));
            S(kMewEncCoordinateRegionLongitudeKey, @((float) anno.coordinate.longitude));
            break;
        default:
            break;
    }
    
}

#pragma mark - Memory

- (void)dealloc {
#ifdef TEST_FLAG
    NSLog(@"[MEWLocationViewController dealloc]");
#endif
}

@end

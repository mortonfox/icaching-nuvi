# icaching-nuvi - iCaching geocaching data preprocessor for Garmin POI Loader

## Introduction

This script reads an [iCaching](http://icaching.eu) database and generates a
GPX file suitable for passing to 
[Garmin POI Loader](http://www8.garmin.com/products/poiloader/) to load onto a Garmin n&uuml;vi
GPS.

We can visualize the flow of geocaching data like so:

    geocaching.com pocket queries -> iCaching -> icaching-nuvi -> POI Loader -> nüvi GPS

icaching-nuvi is based on my older project for GSAK, [nuvigc](https://github.com/mortonfox/nuvigc), which is itself based on a GSAK macro at
[Garmin N&uuml;vi - True Paperless Geocaching](http://geocaching.williamsonnetwork.com).

Note that iCaching itself offers a GPX export feature. The difference is icaching-nuvi adds a lot more geocache information to the name and description fields, so you can read that on the n&uuml;vi.

## Setup

## Usage

    Usage: icnuvi.rb [options] folder [folder...]

    Generate GPX files from iCaching folders.

	-d, --output-dir=DIR             Specify output directory. Default: current directory
	-h, -?, --help                   Print this help.

To use icaching-nuvi, just run icnuvi.rb with iCaching folder names as parameters.
For example:

    icnuvi.rb home delaware maryland

That command will produce one GPX file, one JPG, and one BMP for each folder. The two image files are simple icons (X in a yellow box) that will indicate geocaches on the n&uuml;vi map screen. At this time, there is no support yet for changing the geocache icon.

## Caution

Avoid using numbers in iCaching folder names. POI Loader will convert waypoints
from those folders to speed alerts instead of regular POIs and you will not be
able to route to them.


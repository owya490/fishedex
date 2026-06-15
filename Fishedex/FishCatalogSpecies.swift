import Foundation

/// Typed reference to a species in `Fish.catalog`.
///
/// Use the static members below when defining fishing locations — each one maps to
/// an exact Dex catalog name, so typos are caught at compile time (autocomplete)
/// and invalid names fail in debug builds on launch.
struct FishSpeciesRef: Hashable, Sendable {
    let name: String

    fileprivate init(name: String) {
        #if DEBUG
        assert(
            Fish.catalogSpeciesNames.contains(name),
            "FishSpeciesRef '\(name)' is not in Fish.catalog — check Fish.swift or regenerate FishCatalogSpecies.swift"
        )
        #endif
        self.name = name
    }

    func resolve(in catalog: [Fish]) -> Fish? {
        catalog.first { $0.name == name }
    }
}

extension FishSpeciesRef {

    static let yellowfinBream = FishSpeciesRef(name: "Yellowfin Bream")
    static let australianSalmon = FishSpeciesRef(name: "Australian Salmon")
    static let mackerelNarrowBarredSpanish = FishSpeciesRef(name: "Mackerel (Narrow-barred Spanish)")
    static let flatheadTiger = FishSpeciesRef(name: "Flathead (Tiger)")
    static let pacificOyster = FishSpeciesRef(name: "Pacific Oyster")
    static let brownTrout = FishSpeciesRef(name: "Brown Trout")
    static let prawnSchoolPrawn = FishSpeciesRef(name: "Prawn - School Prawn")
    static let flatheadBluespotted = FishSpeciesRef(name: "Flathead (Bluespotted)")
    static let amberjack = FishSpeciesRef(name: "Amberjack")
    static let sharkWhaler = FishSpeciesRef(name: "Shark - Whaler")
    static let blueGroper = FishSpeciesRef(name: "Blue Groper")
    static let sharkWobbegong = FishSpeciesRef(name: "Shark - Wobbegong")
    static let sandWhiting = FishSpeciesRef(name: "Sand Whiting")
    static let beachWorm = FishSpeciesRef(name: "Beach Worm")
    static let yellowfinTuna = FishSpeciesRef(name: "Yellowfin Tuna")
    static let longtailTuna = FishSpeciesRef(name: "Longtail Tuna")
    static let mudCrab = FishSpeciesRef(name: "Mud Crab")
    static let leatherjacket = FishSpeciesRef(name: "Leatherjacket")
    static let marlinBlue = FishSpeciesRef(name: "Marlin (Blue)")
    static let trevallies = FishSpeciesRef(name: "Trevallies")
    static let sharkBlue = FishSpeciesRef(name: "Shark - Blue")
    static let mulletPoddy = FishSpeciesRef(name: "Mullet (Poddy)")
    static let mulloway = FishSpeciesRef(name: "Mulloway")
    static let brookTrout = FishSpeciesRef(name: "Brook Trout")
    static let cockles = FishSpeciesRef(name: "Cockles")
    static let flounder = FishSpeciesRef(name: "Flounder")
    static let shortbillSpearfish = FishSpeciesRef(name: "Shortbill Spearfish")
    static let prawnBlackTiger = FishSpeciesRef(name: "Prawn - Black Tiger")
    static let morwongJackass = FishSpeciesRef(name: "Morwong (Jackass)")
    static let snapper = FishSpeciesRef(name: "Snapper")
    static let easternRockLobster = FishSpeciesRef(name: "Eastern Rock Lobster")
    static let rockBlackfish = FishSpeciesRef(name: "Rock Blackfish")
    static let marlinStriped = FishSpeciesRef(name: "Marlin (Striped)")
    static let tarwhine = FishSpeciesRef(name: "Tarwhine")
    static let marlinBlack = FishSpeciesRef(name: "Marlin (Black)")
    static let murrayCrayfish = FishSpeciesRef(name: "Murray Crayfish")
    static let goldenPerch = FishSpeciesRef(name: "Golden Perch")
    static let mangroveJack = FishSpeciesRef(name: "Mangrove Jack")
    static let mackerelSpotted = FishSpeciesRef(name: "Mackerel (Spotted)")
    static let yabby = FishSpeciesRef(name: "Yabby")
    static let spannerCrab = FishSpeciesRef(name: "Spanner Crab")
    static let sydneyRockOyster = FishSpeciesRef(name: "Sydney Rock Oyster")
    static let blackBream = FishSpeciesRef(name: "Black Bream")
    static let gemfish = FishSpeciesRef(name: "Gemfish")
    static let cunjevoi = FishSpeciesRef(name: "Cunjevoi")
    static let hairtail = FishSpeciesRef(name: "Hairtail")
    static let hapuku = FishSpeciesRef(name: "Hapuku")
    static let bonito = FishSpeciesRef(name: "Bonito")
    static let purpleSeaUrchin = FishSpeciesRef(name: "Purple Sea Urchin")
    static let octopus = FishSpeciesRef(name: "Octopus")
    static let nativeOyster = FishSpeciesRef(name: "Native Oyster")
    static let bassGroper = FishSpeciesRef(name: "Bass Groper")
    static let freshwaterCatfish = FishSpeciesRef(name: "Freshwater Catfish")
    static let spinyCrayfish = FishSpeciesRef(name: "Spiny Crayfish")
    static let mahiMahiDolphinfish = FishSpeciesRef(name: "Mahi Mahi (Dolphinfish)")
    static let atlanticSalmon = FishSpeciesRef(name: "Atlantic Salmon")
    static let morwongBanded = FishSpeciesRef(name: "Morwong (Banded)")
    static let blueSwimmerCrab = FishSpeciesRef(name: "Blue Swimmer Crab")
    static let greyMorwongRubberLip = FishSpeciesRef(name: "Grey Morwong (Rubber Lip)")
    static let murrayCod = FishSpeciesRef(name: "Murray Cod")
    static let sharkMako = FishSpeciesRef(name: "Shark - Mako")
    static let commercialScallop = FishSpeciesRef(name: "Commercial Scallop")
    static let bandedRockCodBarCod = FishSpeciesRef(name: "Banded Rock Cod (Bar Cod)")
    static let cuttlefish = FishSpeciesRef(name: "Cuttlefish")
    static let balmainBug = FishSpeciesRef(name: "Balmain Bug")
    static let tailor = FishSpeciesRef(name: "Tailor")
    static let rainbowTrout = FishSpeciesRef(name: "Rainbow Trout")
    static let slipperLobster = FishSpeciesRef(name: "Slipper Lobster")
    static let carp = FishSpeciesRef(name: "Carp")
    static let samsonfish = FishSpeciesRef(name: "Samsonfish")
    static let luderick = FishSpeciesRef(name: "Luderick")
    static let southernRockLobster = FishSpeciesRef(name: "Southern Rock Lobster")
    static let cobia = FishSpeciesRef(name: "Cobia")
    static let albacore = FishSpeciesRef(name: "Albacore")
    static let tropicalRockLobsterPaintedAndOrnate = FishSpeciesRef(name: "Tropical Rock Lobster (Painted and Ornate)")
    static let mulletSea = FishSpeciesRef(name: "Mullet (Sea)")
    static let turbanSnails = FishSpeciesRef(name: "Turban Snails")
    static let morwongRed = FishSpeciesRef(name: "Morwong (Red)")
    static let swordfish = FishSpeciesRef(name: "Swordfish")
    static let easternRedScorpionfishRedRockCod = FishSpeciesRef(name: "Eastern Red Scorpionfish (Red Rock Cod)")
    static let sailfish = FishSpeciesRef(name: "Sailfish")
    static let sole = FishSpeciesRef(name: "Sole")
    static let sharkSchool = FishSpeciesRef(name: "Shark - School")
    static let pearlPerch = FishSpeciesRef(name: "Pearl Perch")
    static let estuaryPerch = FishSpeciesRef(name: "Estuary Perch")
    static let easternSchoolWhiting = FishSpeciesRef(name: "Eastern School Whiting")
    static let squid = FishSpeciesRef(name: "Squid")
    static let wahoo = FishSpeciesRef(name: "Wahoo")
    static let australianSawtail = FishSpeciesRef(name: "Australian Sawtail")
    static let mosesSnapper = FishSpeciesRef(name: "Moses Snapper")
    static let sharkHammerhead = FishSpeciesRef(name: "Shark - Hammerhead")
    static let bigeyeTuna = FishSpeciesRef(name: "Bigeye Tuna")
    static let redfinPerch = FishSpeciesRef(name: "Redfin Perch")
    static let southernBluefinTuna = FishSpeciesRef(name: "Southern Bluefin Tuna")
    static let blacklipAbalone = FishSpeciesRef(name: "Blacklip Abalone")
    static let bluefish = FishSpeciesRef(name: "Bluefish")
    static let eelsShortAndLongFinned = FishSpeciesRef(name: "Eels (Short and Long-finned)")
    static let flatheadDusky = FishSpeciesRef(name: "Flathead (Dusky)")
    static let garfish = FishSpeciesRef(name: "Garfish")
    static let teraglin = FishSpeciesRef(name: "Teraglin")
    static let australianBass = FishSpeciesRef(name: "Australian Bass")
    static let blueEyeTrevalla = FishSpeciesRef(name: "Blue-eye Trevalla")
    static let silverPerch = FishSpeciesRef(name: "Silver Perch")
}

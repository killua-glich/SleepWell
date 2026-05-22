import AppIntents

enum NapType: String, AppEnum {
    case power
    case deep

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Nap Type"

    static let caseDisplayRepresentations: [NapType: DisplayRepresentation] = [
        .power: "Power nap (20 minutes)",
        .deep: "Deep rest (90 minutes)"
    ]
}

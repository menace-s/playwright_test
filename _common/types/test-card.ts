// "Cartouche" d'info affichée dans les logs avant l'exécution d'un test.
//
// Nommé `TestCard` (et non `TestInfo`) exprès : Playwright a déjà son propre
// type natif `TestInfo` (2e argument des callbacks de test), on évite toute
// collision de nom avec lui.

export interface TestCard {
    /** identifiant court du cas de test, ex: "TC-01" */
    id: string;
    /** référence métier / ticket, ex: "LOGIN-001" */
    reference: string;
    /** titre lisible du cas de test */
    title: string;
    /** description optionnelle, 1 ligne */
    description?: string;
}

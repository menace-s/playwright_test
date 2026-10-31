// Façade : actions bas niveau réutilisables, avec logging systématique.
// Les pages/ fournissent les Locator, les specs (ou les pages) appellent
// ces méthodes plutôt que .click()/.fill() directement partout.

import { type Locator } from '@playwright/test';
import { logger } from './logger';

export class Fonction {
    /** Attend qu'un élément soit visible et le retourne. */
    async waitDisplayed(locator: Locator, label: string): Promise<Locator> {
        await locator.waitFor({ state: 'visible' });
        return locator;
    }

    /** Clique sur un élément (Playwright attend déjà qu'il soit cliquable). */
    async clickElement(locator: Locator, label: string) {
        logger.step(`Clic sur ${label}`);
        await locator.click();
    }

    /** Attend explicitement qu'un élément soit visible puis clique dessus. */
    async waitAndClick(locator: Locator, label: string) {
        await this.waitDisplayed(locator, label);
        await this.clickElement(locator, label);
    }

    /** Attend qu'un champ soit visible puis y saisit du texte. */
    async typeText(locator: Locator, text: string, label: string) {
        await this.waitDisplayed(locator, label);
        logger.step(`Saisie dans ${label}`);
        await locator.fill(text);
    }

    /** Attend qu'un élément soit visible puis lit son texte. */
    async getText(locator: Locator, label: string): Promise<string> {
        await this.waitDisplayed(locator, label);
        const text = (await locator.textContent())?.trim() ?? '';
        logger.debug(`Texte lu dans ${label} : "${text}"`);
        return text;
    }
}

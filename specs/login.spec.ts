import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { logger } from '../utils/logger';
import type { TestCard } from '../_common/types/test-card';

const card: TestCard = {
    id: 'TC-01',
    reference: 'LOGIN-001',
    title: 'Connexion utilisateur',
    description: 'Un compte Admin peut se connecter et accéder au dashboard',
};

test.describe('Connexion', () => {
    test.beforeEach(() => {
        logger.testCard(card);
    });

    test('un utilisateur peut se connecter à OrangeHRM Demo', async ({ page }) => {
        const loginPage = new LoginPage(page);

        await loginPage.goto();
        await loginPage.login('Admin', 'admin123');

        // Connexion réussie : redirection vers le dashboard
        await expect(page).toHaveURL(/dashboard/);
        await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

        // Connecté avec le compte Admin : le menu latéral doit exposer le module "Admin"
        // (seuls les comptes avec les droits administrateur y ont accès)
        await expect(page.getByRole('link', { name: 'Admin', exact: true })).toBeVisible();

        // Le nom de l'utilisateur connecté apparaît dans le menu en haut à droite
        await expect(page.locator('.oxd-userdropdown-tab')).toBeVisible();
    });
});

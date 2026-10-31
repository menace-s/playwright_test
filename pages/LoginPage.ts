import { type Page, type Locator } from '@playwright/test';
import { Fonction } from '../utils/fonction';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  private readonly fonction = new Fonction();

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.getByPlaceholder('Username');
    this.passwordInput = page.getByPlaceholder('Password');
    this.loginButton = page.getByRole('button', { name: 'Login' });
  }

  async goto() {
    await this.page.goto('https://opensource-demo.orangehrmlive.com/web/index.php/auth/login');
  }

  async login(username: string, password: string) {
    await this.fonction.typeText(this.usernameInput, username, 'champ utilisateur');
    await this.fonction.typeText(this.passwordInput, password, 'champ mot de passe');
    await this.fonction.waitAndClick(this.loginButton, 'bouton Login');
  }
}

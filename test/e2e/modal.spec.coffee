describe "Mac Modal e2e test", ->
  ptor = null

  beforeEach ->
    browser.get "/test/e2e/modal.html"
    ptor = protractor.getInstance()
    browser.waitForAngular()

  it "should show the registered modal", ->
    button = element(By.id("open-btn"))
    button.click()

    modal = element(By.id("test-modal"))
    expect(modal.isDisplayed()).toBeTruthy()

  it "should hide the modal", ->
    button = element(By.id("open-btn"))
    button.click()

    browser.sleep 500

    modal    = element(By.id("test-modal"))
    closeBtn = element(By.css("#test-modal .mac-close-modal"))

    closeBtn.click()

    expect(modal.isDisplayed()).toBeFalsy()

  it "should hide the modal with 'escape' key", ->
    button = element(By.id("open-keyboard-btn"))
    button.click()

    modal = element(By.id("keyboard-modal"))

    ptor.actions().sendKeys(protractor.Key.ESCAPE).perform()

    expect(modal.isDisplayed()).toBeFalsy()

  it "should close the modal after clicking on overlay", ->
    button = element(By.id("open-overlay-btn"))
    button.click()

    driver = protractor.getInstance().driver
    modal  = driver.findElement(By.id("overlay-modal"))
    driver.executeScript("arguments[0].click()", modal).then ->
      expect(modal.isDisplayed()).toBeFalsy()

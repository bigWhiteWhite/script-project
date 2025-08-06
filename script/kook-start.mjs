import inquirer from 'inquirer'
import puppeteer from "puppeteer-core";
import findChrome from 'carlo/lib/find_chrome.js'

// require('dotenv').config();

function delay(time) {
    return new Promise(function (resolve) {
        setTimeout(resolve, time);
    });
}

const run = async (username, password, kookName) => {
    try {
        let findChromePath = await findChrome({});
        let executablePath = findChromePath.executablePath;
        console.info("🚀 ~ file:cmdb method:loadPrivacyPolicy line:16 -----", process.env.ACCOUNT, process.env.PASSWORD)
        console.info("🚀 ~ file:cmdb method:loadPrivacyPolicy line:16 -----", executablePath)
        puppeteer
            .launch({
                executablePath,
                ignoreHTTPSErrors: true,
                defaultViewport: { width: 1440, height: 800 },
                args: ["--no-sandbox", "--start-maximized"],
                headless: false,
            })
            .then(async (browser) => {
                if (kookName === "") {
                    await browser.close();
                    return false;
                }
                const page = (await browser.pages())[0];
                await page.goto("https://cmdb.xcreditech.com/", { waitUntil: ["networkidle0"] });
                await page.type('#dataForm input[name="username"]', username);
                await page.type('#dataForm input[name="password"]', password);
                await page.click(".loginbtn");
                await page.waitForSelector("body");
                await page.reload();
                const itemSelector = ".sidebar__nav .sidebar__nav__item:nth-of-type(3)";
                await page.waitForFunction(
                    (selector) => {
                        const element = document.querySelector(selector);
                        return element && window.getComputedStyle(element).display === "block";
                    },
                    {},
                    itemSelector
                );
                await page.click(itemSelector);
                await delay(1000);
                await page.waitForSelector("body");
                const aSelector = 'a[href="/tools/kook/"]';
                await page.waitForFunction(
                    (selector) => {
                        const element = document.querySelector(selector);
                        return element && window.getComputedStyle(element).display === "block";
                    },
                    {},
                    aSelector
                );
                await page.click(aSelector);
                // 监听新页签的打开事件
                const [newPage] = await Promise.all([
                    new Promise((resolve) => browser.once("targetcreated", (target) => resolve(target.page()))),
                    page.click("#kook_link"),
                ]);
                await newPage.waitForSelector("body");
                await newPage.waitForSelector(".Yahei .btn:nth-of-type(1)");
                await newPage.click(".Yahei .btn:nth-of-type(1)");
                await newPage.waitForSelector("#appname_form .bs-placeholder");
                await newPage.click("#appname_form .bs-placeholder");
                await newPage.type(".bs-searchbox .form-control", kookName);
                await newPage.click(".optgroup-2.active");
                await newPage.waitForSelector('input[name="online_desc"]');
                await newPage.type('input[name="online_desc"]', `${kookName} ${new Date().toLocaleString()} 发布`);
                await newPage.click("#modal-223002");
                await newPage.waitForSelector("#modal-container-223002");
                await delay(1000);
                await newPage.click("#modal-container-223002 .btn-danger");
                await newPage.waitForSelector("body");
                await delay(180000);
                await browser.close();
                console.log(`${kookName} ${new Date().toLocaleString()} 发布完成`);
            });
    } catch (error) {
        console.log(error);
    }
}

/**
 * @param {*用户名} username
 * @param {*密码} password
 * @param {*kook名称} kookName
 */
const main = async (username, password) => {
    try {
        await inquirer
            .prompt([
                {
                    type: "input",
                    name: "kookName",
                    message: '请输入kookname',
                    validate: (value) => {
                        return value ? Boolean(value) : 'kookName is required';
                    }
                }
            ]).then(async ({ kookName }) => {
                await run(username, password, kookName);
            })
    } catch (error) {
        console.error(error);
    }
};

main(process.env.ACCOUNT, process.env.PASSWORD);

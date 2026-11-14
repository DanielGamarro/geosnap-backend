package com.geosnap.geosnapbackend;

import com.geosnap.geosnapbackend.entity.Company;
import com.geosnap.geosnapbackend.repository.CompanyRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@Transactional
class CompanyRepositoryTests {

    @Autowired
    private CompanyRepository companyRepository;

    @Test
    void savesAndFindsCompany() {
        Company savedCompany = companyRepository.save(new Company("Example Company"));

        assertNotNull(savedCompany.getId());
        assertNotNull(savedCompany.getCreatedAt());

        Company foundCompany = companyRepository.findById(savedCompany.getId())
                .orElseThrow();

        assertEquals("Example Company", foundCompany.getName());
    }
}
